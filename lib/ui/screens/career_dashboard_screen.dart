import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/race/race_stage.dart';
import '../../models/career/career_save.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../models/equipment/frame_model.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/career/bike_manufacturer_negotiation_service.dart';
import '../../services/career/sponsor_negotiation_service.dart';
import '../../services/career/team_chemistry_and_builder_service.dart';
import '../../services/career/training_and_camps_service.dart';
import '../../services/career/transfer_market_service.dart';
import '../../services/career/race_calendar_selection_service.dart';
import '../../services/career/finance_and_budget_service.dart';
import '../../services/career/scouting_and_youth_academy_service.dart';
import '../../services/database/custom_mod_importer_service.dart';
import '../../services/database/save_game_manager.dart';
import '../../models/race/tour_race.dart';
import '../../state/career_controller.dart';
import '../../state/career_state_notifier.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/bike_preview_painter.dart';
import '../widgets/elevation_profile_chart.dart';
import '../widgets/power_curve_chart_widget.dart';
import '../widgets/rider_avatar_painter.dart';
import 'race_simulation_screen.dart';
import 'settings_and_mod_screen.dart';
import 'new_career_setup_screen.dart';

/// Główny pulpit zarządzania drużyną kolarską w trybie kariery (Career Hub).
class CareerDashboardScreen extends ConsumerWidget {
  final bool showAppBar;

  const CareerDashboardScreen({
    super.key,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careerUiState = ref.watch(careerProvider);
    final careerController = ref.read(careerProvider.notifier);
    final simController = ref.read(raceSimulationProvider.notifier);

    final save = careerUiState.save;

    if (save == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bike, size: 56, color: AppColors.goldAccent),
                const SizedBox(height: 16),
                const Text(
                  'PRO PELOTON MANAGER',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rozpocznij nową karierę lub wczytaj istniejący zapis gry.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewCareerSetupScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Kreator Nowej Kariery (2026)'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showSaveSlotsManagerDialog(context, careerController, hasActiveSave: false),
                    icon: const Icon(Icons.folder_shared_outlined),
                    label: const Text('Sloty Zapisu & Wczytaj Grę (1-5 / Auto-Save)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showModManagerDialog(context, careerController, hasActiveSave: false),
                        icon: const Icon(Icons.public, color: AppColors.goldAccent, size: 16),
                        label: const Text('Mody & Real Name Pack', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.goldAccent,
                          side: const BorderSide(color: AppColors.goldAccent),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showImportSaveDialog(context, careerController),
                        icon: const Icon(Icons.file_download_outlined, color: AppColors.cyanAccent, size: 16),
                        label: const Text('Importuj Zapis (PC/Tel)', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.cyanAccent,
                          side: const BorderSide(color: AppColors.cyanAccent),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                if (careerUiState.availableSaves.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 12),
                  const Text(
                    'Dostępne zapisy gry:',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      itemCount: careerUiState.availableSaves.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (ctx, idx) {
                        final s = careerUiState.availableSaves[idx];
                        return ListTile(
                          tileColor: AppColors.surfaceLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: AppTheme.borderColor),
                          ),
                          title: Text(
                            s.saveName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            '${s.playerTeamName} • ${s.currentDate.toIso8601String().substring(0, 10)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          trailing: const Icon(Icons.folder_open, color: AppColors.goldAccent),
                          onTap: () => careerController.loadSave(s.saveId),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final playerTeam = save.playerTeam;
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final playerRoster = save.playerRoster;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: showAppBar
          ? AppBar(
              title: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _parseHexColor(playerTeam.primaryJerseyColorHex),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
            const SizedBox(width: 10),
            Text(playerTeam.name),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                playerTeam.division.name.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (careerUiState.activeSlotNumber != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.goldAccent),
                ),
                child: Text(
                  careerUiState.activeSlotNumber == 0
                      ? 'AUTO-SAVE'
                      : 'SLOT #${careerUiState.activeSlotNumber}',
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.goldAccent),
                  const SizedBox(width: 6),
                  Text(
                    save.currentDate.toIso8601String().substring(0, 10),
                    style: AppTheme.statNumberStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 18),
                  const Icon(Icons.account_balance_wallet, size: 15, color: AppColors.powerZone3),
                  const SizedBox(width: 6),
                  Text(
                    '€${(playerTeam.cashBalanceEur / 1000000).toStringAsFixed(2)} mln',
                    style: AppTheme.statNumberStyle(fontSize: 13, color: AppColors.powerZone3),
                  ),
                ],
              ),
            ),
          ),
          Consumer(
            builder: (ctx, ref, _) {
              final careerState = ref.watch(careerStateNotifierProvider);
              final unread = careerState.unreadMessagesCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail_outline, color: AppColors.goldAccent),
                    tooltip: 'Skrzynka Odbiorcza (Inbox)',
                    onPressed: () => _showInboxDialog(context, ref.read(careerStateNotifierProvider.notifier)),
                  ),
                  if (unread > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.powerZone6,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_suggest_rounded, color: AppColors.goldAccent),
            tooltip: 'Ustawienia 3D & Edytor Bazy (Mody)',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const SettingsAndModScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.public, color: AppColors.goldAccent),
            tooltip: 'Real Name Pack & Modyfikacje (Społeczność)',
            onPressed: () => _showModManagerDialog(context, careerController, hasActiveSave: true),
          ),
          IconButton(
            icon: const Icon(Icons.folder_shared_outlined, color: AppColors.goldAccent),
            tooltip: 'Sloty Zapisu & Auto-Save (1-5)',
            onPressed: () => _showSaveSlotsManagerDialog(context, careerController, hasActiveSave: true),
          ),
        ],
      )
    : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lewa kolumna: Stan wyścigu i infrastruktura
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Karta bieżącego wyścigu / etapu
                  _buildRaceStageHubCard(
                    context: context,
                    activeRace: activeRace,
                    activeStage: activeStage,
                    onStartSimulation: () {
                      if (activeStage != null) {
                        final Map<String, Rider> allRidersMap = {
                          for (final r in save.riders) r.id: r,
                        };
                        final Map<String, CyclingTeam> allTeamsMap = {
                          for (final t in save.teams) t.id: t,
                        };

                        final Map<String, CompleteBike> allBikesMap = {};
                        for (final r in save.riders) {
                          final team = allTeamsMap[r.contract.teamId];
                          final bike = (team?.teamBikes.isNotEmpty ?? false)
                              ? team!.teamBikes.first
                              : null;
                          if (bike != null) {
                            allBikesMap[r.id] = bike;
                          }
                        }

                        simController.initializeStage(
                          stage: activeStage,
                          playerTeamId: save.playerTeamId,
                          allRidersMap: allRidersMap,
                          allBikesMap: allBikesMap,
                          allTeamsMap: allTeamsMap,
                        );

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RaceSimulationScreen(),
                          ),
                        );
                      }
                    },
                    onAdvanceDay: () => careerController.advanceCalendarDay(),
                  ),

                  const SizedBox(height: 20),

                  // 2. Kalendarz Startowy & Dzikie Karty (Wildcards)
                  _buildRaceCalendarAndWildcardsCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),

                  const SizedBox(height: 20),

                  // 3. Rynek transferowy (Okno UCI od 1 sierpnia)
                  _buildTransferMarketCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),

                  const SizedBox(height: 20),

                  // 4. Skauting Młodzieży & Akademia Rozwojowa (U19/U23/Zwift)
                  _buildScoutingAndYouthAcademyCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),

                  const SizedBox(height: 20),

                  // 5. Hierarchia i pociągi pomocników (Team Chemistry & Builder)
                  _buildTeamChemistryAndBuilderCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),

                  const SizedBox(height: 20),

                  // 4. Sponsorzy i negocjacje budżetowe (Sponsor Pitch Deck & Budget)
                  _buildSponsorNegotiationCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),

                  const SizedBox(height: 20),

                  // 5. Menedżer finansowy i przepływ gotówki (Cashflow & Budget)
                  _buildFinanceAndCashflowCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),

                  const SizedBox(height: 20),

                  // 6. Sprzęt rowerowy i tunel aerodynamiczny R&D (Bikes & Wind Tunnel)
                  _buildBikeManufacturerAndAeroCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),

                  const SizedBox(height: 20),

                  // 6. Infrastruktura i zaplecze drużyny
                  _buildFacilitiesCard(
                    save: save,
                    onUpgrade: (type) => careerController.upgradeFacility(type),
                  ),

                  const SizedBox(height: 20),

                  // 7. Społeczność i Real Name Pack (Community Modding)
                  _buildCommunityModdingCard(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),
                ],
              ),
            ),
          ),

          // Prawa kolumna: Skład kolarzy i forma fizyczna
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(top: 20, right: 20, bottom: 20),
              child: Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'SKŁAD DRUŻYNY I FORMA FIZYCZNA',
                            style: TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showAltitudeCampSelectionDialog(context, save, careerController),
                            icon: const Icon(Icons.terrain, size: 14),
                            label: const Text('Obóz Wysokogórski'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.borderColor),
                      Expanded(
                        child: ListView.separated(
                          itemCount: playerRoster.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: AppTheme.borderColor, height: 1),
                          itemBuilder: (ctx, idx) {
                            final r = playerRoster[idx];
                            final double cp = r.physiology.criticalPowerWatts.toDouble();
                            final double wKg = cp / r.physiology.weightKg;
                            final double tsb = r.health.trainingStressBalance;

                            Color tsbColor = AppColors.cyanAccent;
                            String tsbLabel = 'TSB: ${tsb.round()}';
                            if (tsb >= 10 && tsb <= 25) {
                              tsbColor = AppColors.powerZone3;
                              tsbLabel = 'TSB: +${tsb.round()} [Szczyt Formy]';
                            } else if (tsb < -20) {
                              tsbColor = AppColors.powerZone6;
                              tsbLabel = 'TSB: ${tsb.round()} [Zmęczenie]';
                            }

                            return ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.borderColor),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  r.nationalityIso.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.goldAccent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    '${r.firstName} ${r.lastName}',
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      r.specialization.name,
                                      style: const TextStyle(color: AppColors.goldAccent, fontSize: 9, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 2),
                                  Text(
                                    'CP: ${cp.round()}W (${wKg.toStringAsFixed(1)} W/kg) • VO2max: ${r.physiology.vo2Max.toStringAsFixed(1)} • ${r.physiology.weightKg.round()}kg',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: tsbColor.withAlpha(30),
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          tsbLabel,
                                          style: TextStyle(color: tsbColor, fontSize: 9, fontWeight: FontWeight.w800),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'CTL: ${r.health.chronicTrainingLoad.round()} • ATL: ${r.health.acuteTrainingLoad.round()}',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: OutlinedButton.icon(
                                onPressed: () => _showRiderTrainingPlanDialog(context, save, r, careerController),
                                icon: const Icon(Icons.fitness_center, size: 13, color: AppColors.goldAccent),
                                label: const Text('Trening'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.goldAccent,
                                  side: const BorderSide(color: AppColors.goldAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceStageHubCard({
    required BuildContext context,
    required dynamic activeRace,
    required dynamic activeStage,
    required VoidCallback onStartSimulation,
    required VoidCallback onAdvanceDay,
  }) {
    if (activeRace == null || activeStage == null) {
      return Card(
        color: AppColors.surface,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BRAK AKTYWNEGO WYŚCIGU',
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Drużyna przebywa na zgrupowaniu treningowym i regeneracji.',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onAdvanceDay,
                icon: const Icon(Icons.skip_next),
                label: const Text('Przejdź do kolejnego dnia'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activeRace.name.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.primaryAccent),
                  ),
                  child: Text(
                    activeRace.uciCategory.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Etap ${activeStage.stageNumber}: ${activeStage.name}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Dystans: ${activeStage.totalDistanceKm.toStringAsFixed(1)} km • Przewyższenie: +${activeStage.totalElevationGainM.round()} m • Profil: ${activeStage.stageType.name}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (activeStage is RaceStage) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ElevationProfileChart(
                  stage: activeStage,
                  height: 150,
                  showHeader: false,
                  enableScrubber: true,
                ),
              ),
              const SizedBox(height: 14),
            ] else
              const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStartSimulation,
                    icon: const Icon(Icons.play_circle_filled, size: 20),
                    label: const Text('Wystartuj Etap w Symulatorze 3D'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesCard({
    required CareerSave save,
    required Function(String) onUpgrade,
  }) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INFRASTRUKTURA I ZAPLECZE SPRZĘTOWE',
              style: TextStyle(
                color: AppColors.goldAccent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),
            _buildFacilityRow(
              title: 'Service Course (Baza logistyczna)',
              level: save.serviceCourseLevel,
              description: 'Lepszy sprzęt zapasowy, ochrona przed defektami',
              onUpgrade: () => onUpgrade('serviceCourse'),
            ),
            const Divider(color: AppTheme.borderColor, height: 24),
            _buildFacilityRow(
              title: 'Tunel Aerodynamiczny (Aero R&D)',
              level: save.windTunnelLevel,
              description: 'Niższe opory CdA ram i kół, szybsze czasówki',
              onUpgrade: () => onUpgrade('windTunnel'),
            ),
            const Divider(color: AppTheme.borderColor, height: 24),
            _buildFacilityRow(
              title: 'Centrum Medyczno-Regeneracyjne',
              level: save.medicalCenterLevel,
              description: 'Nogawki kompresyjne, kriokomora, szybszy spadek ATL',
              onUpgrade: () => onUpgrade('medicalCenter'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityRow({
    required String title,
    required int level,
    required String description,
    required VoidCallback onUpgrade,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'POZ. $level / 5',
                      style: const TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        if (level < 5)
          OutlinedButton(
            onPressed: onUpgrade,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: const Text('Ulepsz'),
          )
        else
          const Text(
            'MAX',
            style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w800),
          ),
      ],
    );
  }

  // ===========================================================================
  // KALENDARZ STARTOWY & DZIKIE KARTY (WILDCARDS)
  // ===========================================================================

  Widget _buildRaceCalendarAndWildcardsCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final team = save.playerTeam;
    final calendarEntries = careerController.getCalendarOverview();
    final registeredCount = calendarEntries.where((e) => e.isRegistered).length;
    final grantedWildcardsCount = save.wildcardApplications
        .where((a) => a.teamId == team.id && a.status == WildcardStatus.granted)
        .length;
    final pendingWildcardsCount = save.wildcardApplications
        .where((a) => a.teamId == team.id && a.status == WildcardStatus.pending)
        .length;

    // Pobieramy 3 kluczowe nadchodzące wyścigi
    final upcomingKeyRaces = calendarEntries
        .where((e) =>
            !save.calendar.completedRaceIds.contains(e.race.id) &&
            (e.race.isGrandTour ||
                e.race.uciCategory == RaceCategory.monument ||
                e.race.uciCategory == RaceCategory.worldTourStageRace))
        .take(3)
        .toList();

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.goldAccent.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek karty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month,
                          color: AppColors.goldAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KALENDARZ STARTOWY & DZIKIE KARTY',
                              style: TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              team.division == TeamDivision.worldTour
                                  ? 'Dywizja WorldTour: Gwarantowany i obowiązkowy start we wszystkich wyścigach WT'
                                  : (team.division == TeamDivision.proTeam
                                      ? 'Dywizja ProTeam: Wymagane Dzikie Karty (Wildcards) na Grand Toury i Monumenty'
                                      : 'Dywizja Continental: Kalendarz krajowy ProSeries i Class 1'),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showFullCalendarAndWildcardsDialog(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('Zarządzaj Kalendarzem'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pigułki statystyk
            Row(
              children: [
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Wyścigi w programie',
                    value: '$registeredCount / ${calendarEntries.length}',
                    color: AppColors.primaryAccent,
                    icon: Icons.check_circle_outline,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Przyznane Wildcards',
                    value: team.division == TeamDivision.worldTour
                        ? 'Automat (WT)'
                        : '$grantedWildcardsCount',
                    color: AppColors.goldAccent,
                    icon: Icons.stars,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Wnioski w toku',
                    value: '$pendingWildcardsCount',
                    color: Colors.cyanAccent,
                    icon: Icons.hourglass_top,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 12),

            const Text(
              'KLUCZOWE NADCHODZĄCE STARTY & STATUS ZAPROSZEŃ:',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            // Lista 3 kluczowych wyścigów
            ...upcomingKeyRaces.map((entry) {
              return _buildCalendarRaceRow(
                context: context,
                entry: entry,
                save: save,
                careerController: careerController,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarMetricPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarRaceRow({
    required BuildContext context,
    required TeamRaceCalendarEntry entry,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final race = entry.race;
    final organizer = entry.organizer;
    final status = entry.status;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case WildcardStatus.automaticEntry:
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Gwarantowany start (WT)';
        statusIcon = Icons.verified;
        break;
      case WildcardStatus.granted:
        statusColor = AppColors.goldAccent;
        statusText = 'Dzika Karta Przyznana';
        statusIcon = Icons.stars;
        break;
      case WildcardStatus.eligibleToApply:
        statusColor = const Color(0xFFFF9800);
        statusText = 'Wymaga Wniosku (ProTeam)';
        statusIcon = Icons.edit_calendar;
        break;
      case WildcardStatus.pending:
        statusColor = Colors.cyanAccent;
        statusText = 'Wniosek w toku';
        statusIcon = Icons.hourglass_top;
        break;
      case WildcardStatus.rejected:
        statusColor = const Color(0xFFE53935);
        statusText = 'Wniosek Odrzucony';
        statusIcon = Icons.cancel;
        break;
      case WildcardStatus.notEligible:
        statusColor = Colors.grey;
        statusText = 'Brak uprawnień';
        statusIcon = Icons.lock_outline;
        break;
      case WildcardStatus.withdrawn:
        statusColor = Colors.blueGrey;
        statusText = 'Wycofany';
        statusIcon = Icons.remove_circle_outline;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: entry.isRegistered ? statusColor.withAlpha(80) : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Flaga i data
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              '${race.countryIso} • ${race.startMonth.toString().padLeft(2, '0')}.${race.startDay.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Nazwa wyścigu i organizator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        race.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: _parseHexColor(organizer.badgeColorHex).withAlpha(40),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _parseHexColor(organizer.badgeColorHex).withAlpha(120),
                        ),
                      ),
                      child: Text(
                        organizer.name.split(' ').first,
                        style: TextStyle(
                          color: _parseHexColor(organizer.badgeColorHex),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${race.stages.length} ${race.stages.length == 1 ? "etap" : (race.stages.length < 5 ? "etapy" : "etapów")} • ${race.totalRaceDistanceKm.toStringAsFixed(0)} km • Pula: €${(race.prizePoolEur / 1000).toStringAsFixed(0)}k',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Status Badge lub Przycisk akcji
          if (status == WildcardStatus.eligibleToApply)
            ElevatedButton.icon(
              onPressed: () => _showWildcardApplicationDialog(
                context: context,
                race: race,
                save: save,
                careerController: careerController,
              ),
              icon: const Icon(Icons.send, size: 12),
              label: const Text('Aplikuj o Wildcard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            )
          else if (status == WildcardStatus.granted || status == WildcardStatus.rejected)
            OutlinedButton.icon(
              onPressed: () {
                final app = entry.application ??
                    save.wildcardApplications.firstWhere(
                      (a) => a.raceId == race.id && a.teamId == save.playerTeamId,
                    );
                _showWildcardDecisionLetterDialog(
                  context: context,
                  application: app,
                  organizer: organizer,
                );
              },
              icon: Icon(statusIcon, size: 12, color: statusColor),
              label: Text(statusText),
              style: OutlinedButton.styleFrom(
                foregroundColor: statusColor,
                side: BorderSide(color: statusColor.withAlpha(120)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: statusColor.withAlpha(100)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(statusIcon, color: statusColor, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL PEŁNEGO KALENDARZA WYŚCIGOWEGO I DZIKICH KART
  // ===========================================================================

  void _showFullCalendarAndWildcardsDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    String selectedCategoryFilter = 'all';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stfCtx, setState) {
            final allEntries = careerController.getCalendarOverview();

            final filteredEntries = allEntries.where((entry) {
              if (selectedCategoryFilter == 'grandTour') {
                return entry.race.isGrandTour;
              } else if (selectedCategoryFilter == 'monument') {
                return entry.race.uciCategory == RaceCategory.monument;
              } else if (selectedCategoryFilter == 'stageRace') {
                return entry.race.uciCategory == RaceCategory.worldTourStageRace;
              } else if (selectedCategoryFilter == 'oneDay') {
                return entry.race.uciCategory == RaceCategory.worldTourOneDay;
              } else if (selectedCategoryFilter == 'registered') {
                return entry.isRegistered;
              }
              return true;
            }).toList();

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                width: 920,
                height: 720,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek modala
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.event_note, color: AppColors.goldAccent, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OFICJALNY KALENDARZ UCI & DZIKIE KARTY (${save.currentSeasonYear})',
                                  style: const TextStyle(
                                    color: AppColors.goldAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Drużyna: ${save.playerTeam.name} (${save.playerTeam.division.name.toUpperCase()}) • Punkty UCI: ${save.playerTeam.uciPointsSeason}',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                careerController.simulateSeasonWildcardAllocation();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.surface,
                                    content: Text(
                                      'Przeprowadzono symulację przydziału dzikich kart dla całego peletonu!',
                                      style: TextStyle(color: AppColors.goldAccent),
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.auto_awesome, size: 14),
                              label: const Text('Symuluj Wildcards Peletonu'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                                foregroundColor: AppColors.goldAccent,
                                side: const BorderSide(color: AppColors.goldAccent),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () => Navigator.pop(dialogCtx),
                              icon: const Icon(Icons.close, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Filtry kategorii wyścigów
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Wszystkie (${allEntries.length})',
                            isSelected: selectedCategoryFilter == 'all',
                            onTap: () => setState(() => selectedCategoryFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Grand Toury (3)',
                            isSelected: selectedCategoryFilter == 'grandTour',
                            onTap: () => setState(() => selectedCategoryFilter = 'grandTour'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Monumenty (5)',
                            isSelected: selectedCategoryFilter == 'monument',
                            onTap: () => setState(() => selectedCategoryFilter = 'monument'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Etapówki WorldTour',
                            isSelected: selectedCategoryFilter == 'stageRace',
                            onTap: () => setState(() => selectedCategoryFilter = 'stageRace'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Klasyki Jednodniowe',
                            isSelected: selectedCategoryFilter == 'oneDay',
                            onTap: () => setState(() => selectedCategoryFilter = 'oneDay'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Mój Program (${allEntries.where((e) => e.isRegistered).length})',
                            isSelected: selectedCategoryFilter == 'registered',
                            onTap: () => setState(() => selectedCategoryFilter = 'registered'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),

                    // Lista wyścigów w kalendarzu
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final entry = filteredEntries[idx];
                          final race = entry.race;
                          final org = entry.organizer;
                          final status = entry.status;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: entry.isRegistered
                                    ? AppColors.goldAccent.withAlpha(80)
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Data i kraj
                                Container(
                                  width: 85,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        race.countryIso,
                                        style: const TextStyle(
                                          color: AppColors.goldAccent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${race.startMonth.toString().padLeft(2, '0')}.${race.startDay.toString().padLeft(2, '0')}',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Szczegóły wyścigu
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            race.name,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _parseHexColor(org.badgeColorHex).withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(
                                                color: _parseHexColor(org.badgeColorHex).withAlpha(120),
                                              ),
                                            ),
                                            child: Text(
                                              '${org.name.split(' ').first} (${org.directorName})',
                                              style: TextStyle(
                                                color: _parseHexColor(org.badgeColorHex),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${race.isGrandTour ? "Grand Tour (21 etapów)" : (race.stages.length == 1 ? "Wyścig jednodniowy" : "${race.stages.length} etapów")} • Dystans: ${race.totalRaceDistanceKm.toStringAsFixed(0)} km • Przewyższenie: ${race.totalRaceElevationGainM.toStringAsFixed(0)} m • Pula: €${(race.prizePoolEur / 1000).toStringAsFixed(0)}k',
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Filozofia organizatora: „${org.philosophy}”',
                                        style: TextStyle(
                                          color: AppColors.textSecondary.withAlpha(180),
                                          fontSize: 10,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Przyciski akcji
                                if (status == WildcardStatus.eligibleToApply)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      _showWildcardApplicationDialog(
                                        context: context,
                                        race: race,
                                        save: save,
                                        careerController: careerController,
                                      );
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.send, size: 14),
                                    label: const Text('Złóż Wniosek o Wildcard'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF9800),
                                      foregroundColor: Colors.black,
                                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                                    ),
                                  )
                                else if (status == WildcardStatus.granted || status == WildcardStatus.rejected)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final app = entry.application ??
                                          save.wildcardApplications.firstWhere(
                                            (a) => a.raceId == race.id && a.teamId == save.playerTeamId,
                                          );
                                      _showWildcardDecisionLetterDialog(
                                        context: context,
                                        application: app,
                                        organizer: org,
                                      );
                                    },
                                    icon: Icon(
                                      status == WildcardStatus.granted ? Icons.check_circle : Icons.cancel,
                                      size: 14,
                                    ),
                                    label: Text(
                                      status == WildcardStatus.granted ? 'Dzika Karta Przyznana' : 'Wniosek Odrzucony',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: status == WildcardStatus.granted
                                          ? AppColors.goldAccent
                                          : const Color(0xFFE53935),
                                      foregroundColor: Colors.black,
                                      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                                    ),
                                  )
                                else if (status == WildcardStatus.automaticEntry)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF4CAF50)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.verified, color: Color(0xFF4CAF50), size: 14),
                                        SizedBox(width: 6),
                                        Text(
                                          'WorldTour (Pewny start)',
                                          style: TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.grey.withAlpha(80)),
                                    ),
                                    child: const Text(
                                      'Niedostępny (Continental)',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldAccent : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.goldAccent : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : AppColors.textPrimary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // MODAL EWALUACJI I SKŁADANIA WNIOSKU O DZIKĄ KARTĘ
  // ===========================================================================

  void _showWildcardApplicationDialog({
    required BuildContext context,
    required TourRace race,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final eval = careerController.evaluateWildcardForRace(race);
    if (eval == null) return;

    final organizer = RaceCalendarSelectionService.getOrganizerForRace(race);
    final team = save.playerTeam;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Container(
            width: 720,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withAlpha(30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.send_outlined, color: Color(0xFFFF9800), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WNIOSEK O DZIKĄ KARTĘ: ${race.name.toUpperCase()}',
                                style: const TextStyle(
                                  color: AppColors.goldAccent,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Organizator: ${organizer.name} • Dyrektor: ${organizer.directorName}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Szacunkowa punktacja i szanse
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: eval.isApproved
                            ? const Color(0xFF4CAF50).withAlpha(120)
                            : const Color(0xFFFF9800).withAlpha(120),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SZACOWANA OCENA KANDYDATURY:',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${eval.overallScore.toStringAsFixed(1)} / 100 pkt',
                              style: TextStyle(
                                color: eval.isApproved ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              eval.isApproved
                                  ? 'Komitet organizacyjny wstępnie pozytywnie opiniuje wniosek'
                                  : 'Ocena poniżej progu kwalifikacyjnego komitetu',
                              style: TextStyle(
                                color: eval.isApproved ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Próg wymagany:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                              Text(
                                '${race.isGrandTour ? "65.0" : (race.uciCategory == RaceCategory.monument ? "58.0" : "52.0")} pkt',
                                style: const TextStyle(color: AppColors.goldAccent, fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),
                  const Text('SZCZEGÓŁOWE KRYTERIA ORGANIZATORA (4 FILARY):', style: TextStyle(color: AppColors.goldAccent, fontSize: 11, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),

                  // 4 Filary oceny
                  _buildEvaluationPillarRow(
                    title: '1. Ranking UCI & Punkty Sezonu (Waga 35%)',
                    score: eval.rankingScore,
                    subtitle: 'Dorobek punktowy zespołu (${team.uciPointsSeason} pkt) na tle pozostałych ekip ProTeam',
                  ),
                  const SizedBox(height: 10),
                  _buildEvaluationPillarRow(
                    title: '2. Dopasowanie Narodowości Sponsora & Bazy (Waga 30%)',
                    score: eval.nationalityScore,
                    subtitle: 'Powiązania z krajem gospodarza (${race.countryIso}), sponsorzy i lokalni kolarze',
                  ),
                  const SizedBox(height: 10),
                  _buildEvaluationPillarRow(
                    title: '3. Waleczność, Ucieczki & Harcownicy (Waga 20%)',
                    score: eval.combativityScore,
                    subtitle: 'Specjaliści ucieczek, wysokie Race IQ i gwarancja godzin ekspozycji w TV',
                  ),
                  const SizedBox(height: 10),
                  _buildEvaluationPillarRow(
                    title: '4. Jakość Składu & Gwiazdy (Waga 15%)',
                    score: eval.rosterStarScore,
                    subtitle: 'Rozpoznawalne nazwiska, liderzy klasyfikacji i perspektywiczne talenty',
                  ),

                  const SizedBox(height: 18),
                  const Divider(color: AppTheme.borderColor),
                  const SizedBox(height: 12),

                  // Mocne i słabe strony
                  if (eval.strengths.isNotEmpty) ...[
                    const Text('Atuty kandydatury:', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w700, fontSize: 11)),
                    const SizedBox(height: 6),
                    ...eval.strengths.map((s) => Text(' • $s', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11))),
                    const SizedBox(height: 10),
                  ],

                  if (eval.weaknesses.isNotEmpty) ...[
                    const Text('Wątpliwości selekcjonerów:', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.w700, fontSize: 11)),
                    const SizedBox(height: 6),
                    ...eval.weaknesses.map((w) => Text(' • $w', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11))),
                    const SizedBox(height: 14),
                  ],

                  // Przyciski akcji
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Anuluj'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          final application = careerController.applyForWildcard(race.id);
                          if (application != null) {
                            _showWildcardDecisionLetterDialog(
                              context: context,
                              application: application,
                              organizer: organizer,
                            );
                          }
                        },
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Złóż Oficjalny Wniosek'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEvaluationPillarRow({
    required String title,
    required double score,
    required String subtitle,
  }) {
    Color barColor;
    if (score >= 75) {
      barColor = const Color(0xFF4CAF50);
    } else if (score >= 55) {
      barColor = AppColors.goldAccent;
    } else {
      barColor = const Color(0xFFFF9800);
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
              Text(
                '${score.toStringAsFixed(1)} / 100',
                style: TextStyle(color: barColor, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (score / 100.0).clamp(0.0, 1.0),
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL OFICJALNEGO LISTU I DECYZJI ORGANIZATORA
  // ===========================================================================

  void _showWildcardDecisionLetterDialog({
    required BuildContext context,
    required WildcardApplication application,
    required RaceOrganizer organizer,
  }) {
    final isGranted = application.status == WildcardStatus.granted;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isGranted ? AppColors.goldAccent : const Color(0xFFE53935),
            ),
          ),
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nagłówek statusu
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isGranted ? Icons.verified : Icons.cancel,
                            color: isGranted ? AppColors.goldAccent : const Color(0xFFE53935),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isGranted ? 'DZIKA KARTA PRZYZNANA!' : 'DECYZJA: WNIOSEK ODRZUCONY',
                                style: TextStyle(
                                  color: isGranted ? AppColors.goldAccent : const Color(0xFFE53935),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              Text(
                                '${application.raceName} • ${organizer.name}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Cytat dyrektora wyścigu
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _parseHexColor(organizer.badgeColorHex).withAlpha(100),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.format_quote,
                          color: _parseHexColor(organizer.badgeColorHex),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            application.directorQuote,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Oficjalny list komitetu
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      application.officialLetter,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        height: 1.45,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                        child: const Text('Zamknij'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransferMarketCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final bool isOpen = TransferMarketService.isTransferWindowOpen(save.currentDate);
    final int daysLeft = TransferMarketService.daysUntilTransferWindowOpens(save.currentDate);
    final expiringRiders = careerController.getExpiringContractRiders();

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RYNEK TRANSFEROWY (UCI)',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isOpen
                        ? AppColors.powerZone3.withValues(alpha: 0.2)
                        : AppColors.powerZone4.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOpen ? AppColors.powerZone3 : AppColors.powerZone4,
                    ),
                  ),
                  child: Text(
                    isOpen ? 'OKNO OTWARTE' : 'OTWARCIE 1 SIERPNIA',
                    style: TextStyle(
                      color: isOpen ? AppColors.powerZone3 : AppColors.powerZone4,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isOpen
                  ? 'Oficjalne okno rejestracji umów na sezon ${save.currentSeasonYear + 1} jest otwarte. Możesz negocjować z agentami kolarzy.'
                  : 'Do oficjalnego otwarcia okna transferowego UCI pozostało $daysLeft dni. Możesz przeglądać rynek i monitorować wygasające umowy.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Dostępnych kolarzy z wygasającymi kontraktami: ${expiringRiders.length}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTransferMarketDialog(
                  context: context,
                  save: save,
                  careerController: careerController,
                  expiringRiders: expiringRiders,
                  isWindowOpen: isOpen,
                ),
                icon: const Icon(Icons.handshake, size: 18),
                label: const Text('Przeglądaj Rynek i Negocjuj z Agentami'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOpen ? AppColors.goldAccent : AppColors.surfaceLight,
                  foregroundColor: isOpen ? Colors.black : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferMarketDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
    required List<Rider> expiringRiders,
    required bool isWindowOpen,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Container(
            width: 780,
            height: 600,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RYNEK TRANSFEROWY – WOLNI AGENCI',
                          style: TextStyle(
                            color: AppColors.goldAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Kontrakty wygasające z końcem sezonu ${save.currentSeasonYear}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                Expanded(
                  child: ListView.separated(
                    itemCount: expiringRiders.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppTheme.borderColor, height: 1),
                    itemBuilder: (context, idx) {
                      final rider = expiringRiders[idx];
                      final marketVal = TransferMarketService.calculateMarketValue(rider);
                      final currentTeam = save.getTeamById(rider.contract.teamId);
                      final double cp = rider.physiology.criticalPowerWatts.toDouble();
                      final double wKg = cp / rider.physiology.weightKg;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        leading: RiderAvatarWidget.fromRider(
                          rider: rider,
                          team: currentTeam,
                          size: 40,
                        ),
                        title: Row(
                          children: [
                            Text(
                              rider.fullName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                rider.specialization.name,
                                style: const TextStyle(
                                  color: AppColors.goldAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${currentTeam?.name ?? rider.contract.teamId} • Wiek: ${rider.age} lat • CP: ${cp.round()}W (${wKg.toStringAsFixed(1)} W/kg) • Wartość: €${(marketVal / 1000).round()}k/rok',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.show_chart, color: AppColors.goldAccent, size: 20),
                              tooltip: 'Krzywa Mocy i Radar',
                              onPressed: () {
                                _showRiderPowerAnalysisDialog(context, save, rider);
                              },
                            ),
                            const SizedBox(width: 4),
                            ElevatedButton(
                              onPressed: () {
                                _showMakeOfferDialog(
                                  context: context,
                                  save: save,
                                  rider: rider,
                                  marketValueEur: marketVal,
                                  careerController: careerController,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text('Złóż Ofertę'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRiderPowerAnalysisDialog(
    BuildContext context,
    CareerSave save,
    Rider riderA,
  ) {
    Rider? defaultRiderB;
    if (save.playerTeam.rosterRiderIds.isNotEmpty) {
      final leaderId = save.playerTeam.rosterRiderIds.first;
      if (leaderId != riderA.id) {
        defaultRiderB = save.getRiderById(leaderId);
      } else if (save.playerTeam.rosterRiderIds.length > 1) {
        defaultRiderB = save.getRiderById(save.playerTeam.rosterRiderIds[1]);
      }
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            child: PowerCurveChartWidget(
              riderA: riderA,
              riderB: defaultRiderB,
              height: 480,
              showHeader: true,
              showTabs: true,
            ),
          ),
        );
      },
    );
  }

  void _showMakeOfferDialog({
    required BuildContext context,
    required CareerSave save,
    required Rider rider,
    required int marketValueEur,
    required CareerController careerController,
  }) {
    int offeredSalary = marketValueEur;
    int durationYears = 2;
    RiderRole selectedRole = (rider.potential >= 78) ? RiderRole.teamLeader : RiderRole.domestique;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              title: Text('Oferta dla: ${rider.fullName}'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wartość rynkowa: €${(marketValueEur / 1000).round()}k / rok',
                      style: const TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Proponowana pensja roczna: €${(offeredSalary / 1000).round()}k',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: offeredSalary.toDouble(),
                      min: (marketValueEur * 0.5).clamp(40000.0, 5000000.0),
                      max: (marketValueEur * 2.0).clamp(80000.0, 8000000.0),
                      divisions: 30,
                      activeColor: AppColors.goldAccent,
                      onChanged: (val) {
                        setState(() {
                          offeredSalary = (val / 1000).round() * 1000;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Rola w zespole:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<RiderRole>(
                      initialValue: selectedRole,
                      dropdownColor: AppColors.surfaceLight,
                      items: const [
                        DropdownMenuItem(
                          value: RiderRole.teamLeader,
                          child: Text('Lider Zespołu (Team Leader)'),
                        ),
                        DropdownMenuItem(
                          value: RiderRole.coLeader,
                          child: Text('Współlider (Co-Leader)'),
                        ),
                        DropdownMenuItem(
                          value: RiderRole.superDomestique,
                          child: Text('Super Pomocnik (Super Domestique)'),
                        ),
                        DropdownMenuItem(
                          value: RiderRole.domestique,
                          child: Text('Pomocnik (Domestique)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => selectedRole = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Długość kontraktu:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        DropdownButton<int>(
                          value: durationYears,
                          dropdownColor: AppColors.surfaceLight,
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 rok')),
                            DropdownMenuItem(value: 2, child: Text('2 lata')),
                            DropdownMenuItem(value: 3, child: Text('3 lata')),
                            DropdownMenuItem(value: 4, child: Text('4 lata')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => durationYears = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    final result = careerController.submitTransferOffer(
                      riderId: rider.id,
                      annualSalaryEur: offeredSalary,
                      contractDurationYears: durationYears,
                      proposedRole: selectedRole,
                    );

                    _showRiderNegotiationResultDialog(
                      context: context,
                      riderName: rider.fullName,
                      result: result,
                    );
                  },
                  child: const Text('Złóż Ofertę Agentowi'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRiderNegotiationResultDialog({
    required BuildContext context,
    required String riderName,
    required AgentNegotiationResult result,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        Color statusColor;
        String statusLabel;
        IconData statusIcon;

        switch (result.status) {
          case ContractOfferStatus.accepted:
            statusColor = AppColors.powerZone3;
            statusLabel = 'OFERTA ZAAKCEPTOWANA!';
            statusIcon = Icons.check_circle;
            break;
          case ContractOfferStatus.counterOffer:
            statusColor = AppColors.goldAccent;
            statusLabel = 'KONTROFERTA AGENTA';
            statusIcon = Icons.swap_horiz;
            break;
          case ContractOfferStatus.rejected:
          case ContractOfferStatus.pending:
          case ContractOfferStatus.expired:
            statusColor = AppColors.powerZone6;
            statusLabel = 'OFERTA ODRZUCONA';
            statusIcon = Icons.cancel;
            break;
        }

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: statusColor, width: 2),
          ),
          title: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 24),
              const SizedBox(width: 8),
              Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rozmowy z agentem: $riderName',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Text(
                    '"${result.agentQuote}"',
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Ocena poszczególnych filarów oferty (0-100 pkt):',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                _buildScoreRow('Pensja i finanse (35%)', result.salaryScore, 35.0),
                _buildScoreRow('Proponowana rola (25%)', result.roleScore, 25.0),
                _buildScoreRow('Prestiż dywizji UCI (20%)', result.prestigeScore, 20.0),
                _buildScoreRow('Jakość rowerów (10%)', result.equipmentScore, 10.0),
                _buildScoreRow('Konflikt liderów (10%)', result.leaderConflictScore, 10.0),
                if (result.hasLeaderConflict) ...[
                  const SizedBox(height: 8),
                  Text(
                    '⚠️ Konflikt w Grand Tourach z: ${result.conflictingLeaderName ?? "innym liderem"}',
                    style: const TextStyle(color: AppColors.powerZone6, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScoreRow(String label, double score, double maxScore) {
    final double pct = (score / maxScore).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(
            '${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)} pkt',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: pct >= 0.7 ? AppColors.powerZone3 : (pct >= 0.4 ? AppColors.goldAccent : AppColors.powerZone6),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SKAUTING MŁODZIEŻY & AKADEMIA ROZWOJOWA (U19/U23/ZWIFT)
  // ===========================================================================

  Widget _buildScoutingAndYouthAcademyCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final prospects = careerController.getScoutedProspects();
    final academy = careerController.getYouthAcademy() ?? const YouthAcademy();

    final fullyTestedCount = prospects.where((p) => p.isFullyRevealed).length;
    final enrolledCount = academy.enrolledProspectIds.length;

    // Pobieramy 3 najciekawszych kandydatów (np. najwyższy szacowany potencjał)
    final highlightedProspects = List<ScoutedProspect>.from(prospects)
      ..sort((a, b) => b.estimatedMaxPotential.compareTo(a.estimatedMaxPotential));
    final topProspectsPreview = highlightedProspects.take(3).toList();

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.cyanAccent.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek karty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.radar,
                          color: Colors.cyanAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SKAUTING MŁODZIEŻY & AKADEMIA ROZWOJOWA',
                              style: TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${academy.levelName} ($enrolledCount/${academy.maxCapacity} adeptów) • Obserwowana pula: ${prospects.length} kolarzy',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showScoutingAndYouthAcademyDialog(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Centrum Skautingu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Pigułki statystyk
            Row(
              children: [
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Młodzież w Akademii',
                    value: '$enrolledCount / ${academy.maxCapacity}',
                    color: Colors.cyanAccent,
                    icon: Icons.school,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Obserwowana pula',
                    value: '${prospects.length} adeptów',
                    color: AppColors.goldAccent,
                    icon: Icons.visibility,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Przebadani (100% odsłonięte)',
                    value: '$fullyTestedCount odkrytych',
                    color: const Color(0xFF4CAF50),
                    icon: Icons.biotech,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NAJLEPIEJ ROKUJĄCE TALENTY W OBSERWACJI (SZACUNKOWE WIDEŁKI):',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showSendScoutDialog(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),
                  icon: const Icon(Icons.explore, size: 13, color: Colors.cyanAccent),
                  label: const Text('Wyślij Skauta w Teren'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.cyanAccent,
                    side: BorderSide(color: Colors.cyanAccent.withAlpha(120)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Podgląd 3 najlepszych adeptów
            ...topProspectsPreview.map((prospect) {
              return _buildProspectPreviewRow(
                context: context,
                prospect: prospect,
                save: save,
                careerController: careerController,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProspectPreviewRow({
    required BuildContext context,
    required ScoutedProspect prospect,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final badgeColor = _parseHexColor(prospect.source.badgeColorHex);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: prospect.isFullyRevealed
              ? AppColors.goldAccent.withAlpha(100)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Flaga i pochodzenie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              '${prospect.nationalityIso} • ${prospect.age} l.',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nazwisko i źródło
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        prospect.fullName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: badgeColor.withAlpha(100)),
                      ),
                      child: Text(
                        prospect.source.badgeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'FTP: ${prospect.ftpDisplay} • VO2max: ${prospect.vo2MaxDisplay} • Potencjał: ${prospect.potentialDisplay}',
                  style: TextStyle(
                    color: prospect.isFullyRevealed ? AppColors.goldAccent : AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: prospect.isFullyRevealed ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Przyciski akcji
          if (!prospect.isFullyRevealed)
            ElevatedButton.icon(
              onPressed: () {
                final outcome = careerController.testProspectInLab(prospect.id);
                _showProspectLabReportDialog(context, outcome);
              },
              icon: const Icon(Icons.biotech, size: 12),
              label: const Text('Audyt Lab (€1.2k)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            )
          else if (!prospect.isEnrolledInAcademy && !prospect.isPromotedToProTeam)
            ElevatedButton.icon(
              onPressed: () {
                careerController.enrollProspectInAcademy(prospect.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      'Zapisano ${prospect.fullName} do Akademii Młodzieżowej!',
                      style: const TextStyle(color: Colors.cyanAccent),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.school, size: 12),
              label: const Text('Do Akademii'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
              ),
            )
          else if (prospect.isEnrolledInAcademy)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: const Text('W AKADEMII', style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withAlpha(20),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF4CAF50)),
              ),
              child: const Text('PRO TEAM', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 10, fontWeight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL PEŁNEGO CENTRUM SKAUTINGU I AKADEMII
  // ===========================================================================

  void _showScoutingAndYouthAcademyDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    String selectedFilter = 'all';

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stfCtx, setState) {
            final allProspects = careerController.getScoutedProspects();
            final academy = careerController.getYouthAcademy() ?? const YouthAcademy();

            final filteredProspects = allProspects.where((p) {
              if (selectedFilter == 'junior') return p.source == ScoutingSource.juniorU19;
              if (selectedFilter == 'espoir') return p.source == ScoutingSource.espoirsU23;
              if (selectedFilter == 'zwift') return p.source == ScoutingSource.zwiftAcademyVirtual;
              if (selectedFilter == 'amateur') return p.source == ScoutingSource.localAmateurCriterium;
              if (selectedFilter == 'mtb') return p.source == ScoutingSource.mtbGravelCrossover;
              if (selectedFilter == 'enrolled') return p.isEnrolledInAcademy;
              return true;
            }).toList();

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                width: 940,
                height: 740,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek modala
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.radar, color: Colors.cyanAccent, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CENTRUM SKAUTINGU MŁODZIEŻY & AKADEMIA ROZWOJOWA',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dział Skautingu: ${save.playerTeam.staff.scoutsLevel}/100 • ${academy.levelName} (${academy.enrolledProspectIds.length}/${academy.maxCapacity})',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Baner informacyjny akademii młodzieżowej
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.cyanAccent.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school, color: Colors.cyanAccent, size: 22),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    academy.levelName.toUpperCase(),
                                    style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    'Pojemność: ${academy.enrolledProspectIds.length}/${academy.maxCapacity} adeptów • Rozwój: +${((academy.developmentMultiplier - 1.0) * 100).toStringAsFixed(0)}% • Utrzymanie: €${academy.monthlyMaintenanceCostEur}/mies.',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (academy.level < 5)
                            ElevatedButton.icon(
                              onPressed: () {
                                careerController.upgradeYouthAcademy();
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColors.surface,
                                    content: Text('Rozbudowano Akademię Młodzieżową na poziom ${academy.level + 1}!', style: const TextStyle(color: Colors.cyanAccent)),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.upgrade, size: 14),
                              label: Text('Rozbuduj Akademię (€${((academy.level + 1) * 180)}k)'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: Colors.cyanAccent,
                                side: const BorderSide(color: Colors.cyanAccent),
                                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Filtry kategorii adeptów
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Wszyscy (${allProspects.length})',
                            isSelected: selectedFilter == 'all',
                            onTap: () => setState(() => selectedFilter = 'all'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Juniorzy U19',
                            isSelected: selectedFilter == 'junior',
                            onTap: () => setState(() => selectedFilter = 'junior'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'U23 Espoirs',
                            isSelected: selectedFilter == 'espoir',
                            onTap: () => setState(() => selectedFilter = 'espoir'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Zwift / E-cycling',
                            isSelected: selectedFilter == 'zwift',
                            onTap: () => setState(() => selectedFilter = 'zwift'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Kryteria & Amatorzy',
                            isSelected: selectedFilter == 'amateur',
                            onTap: () => setState(() => selectedFilter = 'amateur'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'MTB / Gravel',
                            isSelected: selectedFilter == 'mtb',
                            onTap: () => setState(() => selectedFilter = 'mtb'),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'W mojej Akademii (${allProspects.where((p) => p.isEnrolledInAcademy).length})',
                            isSelected: selectedFilter == 'enrolled',
                            onTap: () => setState(() => selectedFilter = 'enrolled'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),

                    // Lista kandydatów
                    Expanded(
                      child: ListView.separated(
                        itemCount: filteredProspects.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final prospect = filteredProspects[idx];
                          final badgeColor = _parseHexColor(prospect.source.badgeColorHex);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: prospect.isFullyRevealed
                                    ? AppColors.goldAccent.withAlpha(100)
                                    : AppTheme.borderColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Data i kraj
                                Container(
                                  width: 80,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        prospect.nationalityIso,
                                        style: const TextStyle(
                                          color: AppColors.goldAccent,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${prospect.age} lat',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Szczegóły adepta
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            prospect.fullName,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: badgeColor.withAlpha(120)),
                                            ),
                                            child: Text(
                                              prospect.source.badgeLabel,
                                              style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.black26,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppTheme.borderColor),
                                            ),
                                            child: Text(
                                              prospect.discoveryStage.label,
                                              style: TextStyle(
                                                color: prospect.isFullyRevealed
                                                    ? AppColors.goldAccent
                                                    : (prospect.isScouted ? Colors.cyanAccent : AppColors.textSecondary),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Szacowane FTP: ${prospect.ftpDisplay} • VO2max: ${prospect.vo2MaxDisplay} • Potencjał: ${prospect.potentialDisplay}',
                                        style: TextStyle(
                                          color: prospect.isFullyRevealed ? AppColors.goldAccent : AppColors.textPrimary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        prospect.scoutReport,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontStyle: FontStyle.italic),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Przyciski akcji
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!prospect.isFullyRevealed)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          final outcome = careerController.testProspectInLab(prospect.id);
                                          setState(() {});
                                          _showProspectLabReportDialog(context, outcome);
                                        },
                                        icon: const Icon(Icons.biotech, size: 14),
                                        label: const Text('Audyt Lab (€1.2k)'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.cyanAccent,
                                          foregroundColor: Colors.black,
                                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        if (!prospect.isEnrolledInAcademy && !prospect.isPromotedToProTeam)
                                          OutlinedButton(
                                            onPressed: () {
                                              careerController.enrollProspectInAcademy(prospect.id);
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: AppColors.surface,
                                                  content: Text('Zapisano ${prospect.fullName} do Akademii Młodzieżowej!', style: const TextStyle(color: Colors.cyanAccent)),
                                                ),
                                              );
                                            },
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.cyanAccent,
                                              side: const BorderSide(color: Colors.cyanAccent),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                            ),
                                            child: const Text('Do Akademii'),
                                          ),
                                        const SizedBox(width: 6),
                                        if (!prospect.isPromotedToProTeam)
                                          ElevatedButton(
                                            onPressed: () {
                                              careerController.promoteProspectToProTeam(prospect.id);
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  backgroundColor: AppColors.surface,
                                                  content: Text('Podpisano kontrakt Neo-Pro z ${prospect.fullName}! Kolarz w pierwszym zespole.', style: const TextStyle(color: AppColors.goldAccent)),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.goldAccent,
                                              foregroundColor: Colors.black,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                                            ),
                                            child: const Text('Podpisz Neo-Pro'),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // MODAL WYSYŁANIA SKAUTA W TEREN
  // ===========================================================================

  void _showSendScoutDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.cyanAccent),
          ),
          child: Container(
            width: 680,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.explore, color: Colors.cyanAccent, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'WYŚLIJ SKAUTA NA ZAWODY W TEREN',
                            style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Wybierz cel i środowisko skautingowe. Skaut obejrzy zawody i zawęzi widełki parametrów kandydatów:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 14),

                  ...ScoutingSource.values.map((src) {
                    int cost;
                    switch (src) {
                      case ScoutingSource.juniorU19:
                        cost = 2800;
                        break;
                      case ScoutingSource.espoirsU23:
                        cost = 3500;
                        break;
                      case ScoutingSource.zwiftAcademyVirtual:
                        cost = 1800;
                        break;
                      case ScoutingSource.localAmateurCriterium:
                        cost = 1400;
                        break;
                      case ScoutingSource.mtbGravelCrossover:
                        cost = 2200;
                        break;
                    }

                    final canAfford = save.playerTeam.cashBalanceEur >= cost;
                    final badgeColor = _parseHexColor(src.badgeColorHex);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(src.label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(color: badgeColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                      child: Text(src.badgeLabel, style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.w800)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Koszt operacyjny delegacji: €$cost • Dział Skautingu: ${save.playerTeam.staff.scoutsLevel}/100', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: canAfford
                                ? () {
                                    Navigator.pop(dialogCtx);
                                    final outcome = careerController.sendScoutOnMission(src);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: AppColors.surface,
                                        content: Text(outcome.summary, style: const TextStyle(color: Colors.cyanAccent)),
                                      ),
                                    );
                                  }
                                : null,
                            icon: const Icon(Icons.send, size: 12),
                            label: Text('Wyślij (€$cost)'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MODAL CERTYFIKATU BADAŃ LABORATORYJNYCH ADEPTA
  // ===========================================================================

  void _showProspectLabReportDialog(BuildContext context, ProspectLabTestingOutcome outcome) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.goldAccent),
          ),
          child: Container(
            width: 680,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.workspace_premium, color: AppColors.goldAccent, size: 28),
                          SizedBox(width: 12),
                          Text(
                            'AUDYT LABORATORYJNY: ODKRYCIE POTENCJAŁU',
                            style: TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      outcome.labCertificate,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        height: 1.45,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldAccent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
                        ),
                        child: const Text('Zamknij Certyfikat'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamChemistryAndBuilderCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final audit = careerController.analyzeTeamHierarchy();
    final int leadersCount = save.franchiseLeaders.length;
    final int squadsCount = save.dedicatedSquads.length;
    final double harmonyScore = audit?.overallTeamHarmonyScore ?? 50.0;

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'HIERARCHIA I POCIĄGI POMOCNIKÓW',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: harmonyScore >= 70.0
                        ? AppColors.powerZone3.withValues(alpha: 0.2)
                        : (harmonyScore >= 45.0
                            ? AppColors.goldAccent.withValues(alpha: 0.2)
                            : AppColors.powerZone6.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: harmonyScore >= 70.0
                          ? AppColors.powerZone3
                          : (harmonyScore >= 45.0 ? AppColors.goldAccent : AppColors.powerZone6),
                    ),
                  ),
                  child: Text(
                    'CHEMIA: ${harmonyScore.round()}/100',
                    style: TextStyle(
                      color: harmonyScore >= 70.0
                          ? AppColors.powerZone3
                          : (harmonyScore >= 45.0 ? AppColors.goldAccent : AppColors.powerZone6),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Główni Liderzy: $leadersCount / 3 • Aktywne pociągi: $squadsCount',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Buduj zgranie wokół liderów (np. skład pod Tour de France vs Klasyki). Wspólne obozy i starty zwiększają oszczędność na kole (+% aero) i morale.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
            if (audit != null && audit.squadSynergies.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderColor),
              const SizedBox(height: 8),
              ...audit.squadSynergies.map((syn) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          syn.squadName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${syn.draftingEfficiencyBonusPercent}% AERO NA KOLE',
                          style: const TextStyle(
                            color: AppColors.powerZone2,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showHierarchyBuilderDialog(
                      context: context,
                      save: save,
                      careerController: careerController,
                    ),
                    icon: const Icon(Icons.group_add, size: 16),
                    label: const Text('Zarządzaj Liderami'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showTrainingCampDialog(
                      context: context,
                      save: save,
                      careerController: careerController,
                    ),
                    icon: const Icon(Icons.terrain, size: 16),
                    label: const Text('Zorganizuj Obóz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHierarchyBuilderDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        final playerRoster = save.playerRoster;
        final leaders = save.franchiseLeaders;
        final squads = save.dedicatedSquads;

        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Container(
            width: 720,
            height: 560,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'HIERARCHIA ZESPOŁU I POCIĄGI POMOCNIKÓW',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Wyznacz 1-3 Głównych Liderów oraz przypisz im dedykowane pociągi (np. skład pod Tour de France lub Klasyki).',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kolumna 1: Główni Liderzy
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Główni Liderzy (Franchise Riders):',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            if (leaders.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'Brak wyznaczonych liderów. Wybierz kolarzy z kadry poniżej.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              )
                            else
                              ...leaders.map((l) {
                                return ListTile(
                                  dense: true,
                                  tileColor: AppColors.surfaceLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  title: Text(
                                    '#${l.priorityRank} ${l.riderName}',
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    l.focus.label,
                                    style: const TextStyle(color: AppColors.goldAccent, fontSize: 10),
                                  ),
                                );
                              }),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (playerRoster.isNotEmpty) {
                                  // Przykładowe wyznaczenie lidera z najwyższym CP
                                  final sortedRiders = [...playerRoster]
                                    ..sort((a, b) => b.physiology.criticalPowerWatts.compareTo(a.physiology.criticalPowerWatts));

                                  final topRider = sortedRiders.first;
                                  final secondRider = sortedRiders.length > 1 ? sortedRiders[1] : null;

                                  final List<({String riderId, FranchiseRoleFocus focus, int priorityRank})> assignments = [
                                    (
                                      riderId: topRider.id,
                                      focus: FranchiseRoleFocus.grandTourGc,
                                      priorityRank: 1,
                                    ),
                                  ];

                                  if (secondRider != null) {
                                    assignments.add(
                                      (
                                        riderId: secondRider.id,
                                        focus: FranchiseRoleFocus.springCobbledClassics,
                                        priorityRank: 2,
                                      ),
                                    );
                                  }

                                  careerController.assignFranchiseLeaders(assignments);
                                  Navigator.pop(ctx);
                                }
                              },
                              icon: const Icon(Icons.star, size: 16),
                              label: const Text('Auto-wyznacz 2 Liderów'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldAccent,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(color: AppTheme.borderColor),
                      // Kolumna 2: Dedykowane Składy
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dedykowane Pociągi Pomocników:',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            if (squads.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  'Brak utworzonych pociągów pomocników.',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              )
                            else
                              ...squads.map((s) {
                                return ListTile(
                                  dense: true,
                                  tileColor: AppColors.surfaceLight,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  title: Text(
                                    s.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    'Zgranie: ${s.cohesionScore.toStringAsFixed(1)}/100 • Pomocników: ${s.domestiqueRiderIds.length}',
                                    style: const TextStyle(color: AppColors.powerZone2, fontSize: 10),
                                  ),
                                );
                              }),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () {
                                if (playerRoster.length >= 6) {
                                  final leader = playerRoster.first;
                                  final domestiques = playerRoster.skip(1).take(5).map((r) => r.id).toList();

                                  careerController.createDedicatedSquad(
                                    squadName: 'Pociąg pod Tour de France',
                                    leaderRiderId: leader.id,
                                    domestiqueRiderIds: domestiques,
                                    targetSeasonObjective: 'Klasyfikacja Generalna Tour de France',
                                  );
                                  Navigator.pop(ctx);
                                }
                              },
                              icon: const Icon(Icons.train, size: 16),
                              label: const Text('Utwórz Pociąg pod Tour de France'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrainingCampDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    if (save.dedicatedSquads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Najpierw utwórz dedykowany pociąg pomocników, aby wysłać go na zgrupowanie!'),
        ),
      );
      return;
    }

    DedicatedSquad selectedSquad = save.dedicatedSquads.first;
    TrainingCampType selectedCamp = TrainingCampType.teideAltitude;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              title: const Text('Zorganizuj Zgrupowanie Przygotowawcze'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Wybierz pociąg kolarzy:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<DedicatedSquad>(
                      initialValue: selectedSquad,
                      dropdownColor: AppColors.surfaceLight,
                      items: save.dedicatedSquads.map((s) {
                        return DropdownMenuItem(
                          value: s,
                          child: Text('${s.name} (Zgranie: ${s.cohesionScore.round()}/100)'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedSquad = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('Rodzaj obozu przygotowawczego:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<TrainingCampType>(
                      initialValue: selectedCamp,
                      dropdownColor: AppColors.surfaceLight,
                      items: TrainingCampType.values.map((c) {
                        return DropdownMenuItem(
                          value: c,
                          child: Text('${c.title} • €${(c.costEur / 1000).round()}k'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedCamp = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Koszt: €${selectedCamp.costEur}', style: const TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Czas trwania: ${selectedCamp.durationDays} dni'),
                          const SizedBox(height: 2),
                          const Text('Efekty: +20 do +30 pkt zgrania pociągu, +10% do oszczędności na kole, wzrost formy CTL.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    final result = careerController.conductTrainingCamp(
                      squad: selectedSquad,
                      campType: selectedCamp,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text(
                          result.reportDescription,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    );
                  },
                  child: const Text('Wyślij na Zgrupowanie'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSponsorNegotiationCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final playerTeam = save.playerTeam;
    final sponsors = playerTeam.sponsors;
    final int totalAnnualBudgetEur = sponsors.fold<int>(
      0,
      (sum, s) => sum + s.annualBudgetEur,
    );
    final double breakawayRating = SponsorNegotiationService.calculateTeamBreakawayExposure(
      save: save,
    );

    // Szukamy sponsora tytularnego
    final titleSponsor = sponsors.cast<SponsorContract?>().firstWhere(
          (s) => s?.sponsorTier == SponsorTier.titlePrimary,
          orElse: () => null,
        );

    final secondarySponsors = sponsors.where((s) => s.sponsorTier != SponsorTier.titlePrimary).toList();

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.handshake_outlined, size: 20, color: AppColors.goldAccent),
                    SizedBox(width: 8),
                    Text(
                      'SPONSORZY I BUDŻET KORPORACYJNY',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showPitchDeckDialog(context, save, careerController),
                  icon: const Icon(Icons.campaign, size: 16),
                  label: const Text('Pitch Deck (Oferta)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Panel finansowy
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Budżet Sponsoringowy (Roczny)',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '€${(totalAnnualBudgetEur / 1000000).toStringAsFixed(2)}M / rok',
                          style: AppTheme.statNumberStyle(fontSize: 18, color: AppColors.goldAccent),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '+€${((totalAnnualBudgetEur / 12) / 1000).round()}k wpływu miesięcznie',
                          style: const TextStyle(color: AppColors.powerZone3, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 50,
                    color: AppTheme.borderColor,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Wskaźnik Ekspozycji TV (Ucieczki)',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.tv, size: 16, color: AppColors.cyanAccent),
                            const SizedBox(width: 6),
                            Text(
                              '${breakawayRating.round()} / 100 pkt AVE',
                              style: AppTheme.statNumberStyle(fontSize: 16, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Podnosi wycenę prezentacji o +35%',
                          style: TextStyle(color: AppColors.cyanAccent, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Sponsor tytularny
            if (titleSponsor != null) ...[
              const Text(
                'GŁÓWNY SPONSOR TYTULARNY',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.goldAccent.withAlpha(80)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.business, color: AppColors.goldAccent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                titleSponsor.companyName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent.withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'TITLE PRIMARY',
                                  style: TextStyle(
                                    color: AppColors.goldAccent,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Budżet: €${(titleSponsor.annualBudgetEur / 1000000).toStringAsFixed(1)}M/rok • Kontrakt: ${titleSponsor.contractDurationYears} lata • Satysfakcja: ${titleSponsor.sponsorSatisfaction.round()}%',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (titleSponsor.sponsorSatisfaction / 100.0).clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: AppColors.surface,
                          valueColor: AlwaysStoppedAnimation(
                            titleSponsor.sponsorSatisfaction >= 70
                                ? AppColors.powerZone3
                                : (titleSponsor.sponsorSatisfaction >= 40
                                    ? AppColors.powerZone4
                                    : AppColors.powerZone6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.powerZone5.withAlpha(80)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.powerZone5),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Brak sponsora tytularnego! Złóż ofertę korporacji, aby zabezpieczyć stabilność finansową na nowy sezon.',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Partnerzy dodatkowi
            if (secondarySponsors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'PARTNERZY I DRUDZY SPONSORZY',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...secondarySponsors.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.companyName,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        Text(
                          '€${(s.annualBudgetEur / 1000000).toStringAsFixed(2)}M/rok (${s.sponsorTier.name})',
                          style: const TextStyle(color: AppColors.goldAccent, fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _showPitchDeckDialog(
    BuildContext context,
    CareerSave save,
    CareerController careerController,
  ) {
    final prospectiveSponsors = careerController.getProspectiveSponsors();
    PotentialSponsorCompany selectedCompany = prospectiveSponsors.first;
    SponsorTier selectedTier = selectedCompany.defaultTier;
    int requestedBudget = selectedCompany.baseAnnualBudgetEur;
    int durationYears = 2;
    String? featuredStarRiderId;
    final Set<PromisedObjectiveType> selectedObjectives = {
      PromisedObjectiveType.targetStageWinsCount,
      PromisedObjectiveType.breakawayTvAirtimeKm,
    };

    if (save.playerRoster.isNotEmpty) {
      final sortedRoster = [...save.playerRoster]
        ..sort((a, b) => b.careerPointsUci.compareTo(a.careerPointsUci));
      featuredStarRiderId = sortedRoster.first.id;
    }

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              title: const Row(
                children: [
                  Icon(Icons.campaign, color: AppColors.goldAccent),
                  SizedBox(width: 10),
                  Text('Prezentacja Sponsoringowa (Pitch Deck)'),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Wybierz korporację do negocjacji:',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<PotentialSponsorCompany>(
                        initialValue: selectedCompany,
                        dropdownColor: AppColors.surfaceLight,
                        isExpanded: true,
                        items: prospectiveSponsors.map((c) {
                          return DropdownMenuItem(
                            value: c,
                            child: Text(
                              '${c.name} (${c.countryIso}) • Baza: €${(c.baseAnnualBudgetEur / 1000000).toStringAsFixed(1)}M/rok • ${c.industry.name}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedCompany = val;
                              selectedTier = val.defaultTier;
                              requestedBudget = val.baseAnnualBudgetEur;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Karta opisu profilu sponsora
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.track_changes, size: 14, color: AppColors.cyanAccent),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    selectedCompany.marketingFocus.label,
                                    style: const TextStyle(
                                      color: AppColors.cyanAccent,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              selectedCompany.description,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Szczebel sponsoringu i długość
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Szczebel sponsoringu:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<SponsorTier>(
                                  initialValue: selectedTier,
                                  dropdownColor: AppColors.surfaceLight,
                                  items: SponsorTier.values.map((t) {
                                    return DropdownMenuItem(
                                      value: t,
                                      child: Text(t.name),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => selectedTier = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Okres umowy:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  initialValue: durationYears,
                                  dropdownColor: AppColors.surfaceLight,
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('1 rok')),
                                    DropdownMenuItem(value: 2, child: Text('2 lata')),
                                    DropdownMenuItem(value: 3, child: Text('3 lata')),
                                    DropdownMenuItem(value: 4, child: Text('4 lata')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => durationYears = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Budżet roczny (Suwak)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Żądany budżet roczny:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          Text(
                            '€${(requestedBudget / 1000000).toStringAsFixed(2)}M / rok',
                            style: AppTheme.statNumberStyle(fontSize: 14, color: AppColors.goldAccent),
                          ),
                        ],
                      ),
                      Slider(
                        value: requestedBudget.toDouble(),
                        min: (selectedCompany.baseAnnualBudgetEur * 0.5).roundToDouble(),
                        max: (selectedCompany.baseAnnualBudgetEur * 1.5).roundToDouble(),
                        divisions: 20,
                        activeColor: AppColors.goldAccent,
                        onChanged: (val) {
                          setState(() {
                            requestedBudget = ((val / 250000).round() * 250000);
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Gwiazda prezentacji
                      const Text(
                        'Główna gwiazda i twarz prezentacji (Star Power):',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: featuredStarRiderId,
                        dropdownColor: AppColors.surfaceLight,
                        isExpanded: true,
                        items: save.playerRoster.map((r) {
                          final double cp = r.physiology.criticalPowerWatts.toDouble();
                          final double wKg = cp / r.physiology.weightKg;
                          final double star = SponsorNegotiationService.calculateRiderMediaStarRating(r);
                          return DropdownMenuItem(
                            value: r.id,
                            child: Text(
                              '${r.fullName} (${wKg.toStringAsFixed(1)} W/kg, ${r.careerPointsUci} pkt UCI) • Gwiazda: ${star.round()}/100',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => featuredStarRiderId = val);
                        },
                      ),
                      const SizedBox(height: 14),
                      // Obietnice sportowe (Promised Objectives)
                      const Text(
                        'Obietnice sportowe w Pitch Decku (Cele na nowy sezon):',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          children: PromisedObjectiveType.values.map((obj) {
                            final isChecked = selectedObjectives.contains(obj);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: AppColors.primaryAccent,
                              title: Text(
                                obj.label,
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                'Premia za realizację celu: +€${(obj.defaultBonusEur / 1000).round()}k',
                                style: const TextStyle(fontSize: 10, color: AppColors.goldAccent),
                              ),
                              value: isChecked,
                              onChanged: (bool? val) {
                                setState(() {
                                  if (val == true) {
                                    selectedObjectives.add(obj);
                                  } else {
                                    selectedObjectives.remove(obj);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final deck = SponsorPitchDeck(
                      sponsorCompanyId: selectedCompany.id,
                      proposedTier: selectedTier,
                      requestedAnnualBudgetEur: requestedBudget,
                      contractDurationYears: durationYears,
                      featuredStarRiderId: featuredStarRiderId,
                      promisedObjectives: selectedObjectives.toList(),
                    );

                    Navigator.pop(dialogCtx);

                    final pitchResult = careerController.submitSponsorPitchDeck(deck);

                    _showSponsorNegotiationResultDialog(
                      context: context,
                      result: pitchResult,
                      careerController: careerController,
                      company: selectedCompany,
                    );
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Złóż Ofertę Zarządowi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSponsorNegotiationResultDialog({
    required BuildContext context,
    required SponsorPitchResult result,
    required CareerController careerController,
    required PotentialSponsorCompany company,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        Color statusColor;
        String statusTitle;
        IconData statusIcon;

        if (result.isAccepted) {
          statusColor = AppColors.powerZone3;
          statusTitle = 'OFERTA ZAAKCEPTOWANA!';
          statusIcon = Icons.check_circle;
        } else if (result.isCounterOffer) {
          statusColor = AppColors.goldAccent;
          statusTitle = 'KONTROFERTA ZARZĄDU';
          statusIcon = Icons.swap_horiz;
        } else {
          statusColor = AppColors.powerZone6;
          statusTitle = 'PREZENTACJA ODRZUCONA';
          statusIcon = Icons.cancel;
        }

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: statusColor.withAlpha(120)),
          ),
          title: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Zarząd ${company.name}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cytat dyrektora
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote, color: AppColors.goldAccent, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.corporateDirectorQuote,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OCENA PUNKTOWA PREZENTACJI (PITCH AUDIT):',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                // Paski oceny filarów
                _buildScoreBar('Siła Medialna Gwiazdy Zespołu', result.starPowerScore, 30.0, AppColors.goldAccent),
                const SizedBox(height: 6),
                _buildScoreBar('Ekspozycja TV z Ucieczek (AVE)', result.breakawayExposureScore, 25.0, AppColors.cyanAccent),
                const SizedBox(height: 6),
                _buildScoreBar('Wiarygodność Obietnic Sportowych', result.promisesAmbitionScore, 20.0, AppColors.powerZone3),
                const SizedBox(height: 6),
                _buildScoreBar('Realizm Żądanego Budżetu', result.budgetFairnessScore, 15.0, AppColors.powerZone4),
                const SizedBox(height: 6),
                _buildScoreBar('Prestiż Dywizji Zespołu', result.divisionPrestigeScore, 10.0, AppColors.primaryAccent),
                const Divider(color: AppTheme.borderColor, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'ŁĄCZNA NOTA ZARZĄDU:',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    Text(
                      '${result.overallScore.toStringAsFixed(1)} / 100 pkt',
                      style: AppTheme.statNumberStyle(fontSize: 16, color: statusColor),
                    ),
                  ],
                ),
                if (result.resultingContract != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldAccent.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Zaoferowany budżet:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '€${(result.offeredAnnualBudgetEur / 1000000).toStringAsFixed(2)}M / rok',
                              style: AppTheme.statNumberStyle(fontSize: 15, color: AppColors.goldAccent),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Czas trwania:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '${result.contractDurationYears} lata',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(result.resultingContract != null ? 'Odrzuć' : 'Zamknij'),
            ),
            if (result.resultingContract != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  careerController.acceptSponsorContract(result.resultingContract!);

                  final upfrontTranche = (result.offeredAnnualBudgetEur / 12.0).round();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surface,
                      content: Text(
                        'Umowa z ${company.name} podpisana! Pierwsza transza sponsorska (+€${(upfrontTranche / 1000).round()}k) wpłynęła na konto drużyny.',
                        style: const TextStyle(color: AppColors.goldAccent),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Podpisz Kontrakt Sponsorski'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.powerZone3,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildScoreBar(String label, double value, double max, Color color) {
    final double pct = (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            Text('${value.toStringAsFixed(1)} / ${max.toInt()} pkt', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: AppColors.surfaceLight,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MENEDŻER FINANSOWY KLUBU (CASHFLOW & BUDGET)
  // ===========================================================================

  Widget _buildFinanceAndCashflowCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final report = careerController.getMonthlyCashflowReport() ??
        FinanceAndBudgetService.generateMonthlyCashflowReport(save: save);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.goldAccent.withAlpha(50)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nagłówek karty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: AppColors.goldAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MENEDŻER FINANSOWY & CASHFLOW',
                              style: TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Stan konta: €${(save.playerTeam.cashBalanceEur / 1000).toStringAsFixed(0)}k • Płynność: ${report.runwayMonths.toStringAsFixed(1)} mies. • Zdrowie: ${report.financialHealthScore}/100',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showMonthlyCashflowDialog(
                    context: context,
                    save: save,
                    careerController: careerController,
                  ),
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('Raport Cashflow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3 Główne Pigułki Finansowe (Przychody, Wydatki, Wynik Netto)
            Row(
              children: [
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Przychody miesięczne',
                    value: '+€${(report.totalIncomeEur / 1000).toStringAsFixed(0)}k',
                    color: const Color(0xFF4CAF50),
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Koszty operacyjne',
                    value: '-€${(report.totalExpensesEur / 1000).toStringAsFixed(0)}k',
                    color: const Color(0xFFE53935),
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCalendarMetricPill(
                    label: 'Wynik netto (Cashflow)',
                    value:
                        '${report.isProfitable ? '+' : ''}€${(report.netCashflowEur / 1000).toStringAsFixed(0)}k',
                    color: report.isProfitable ? AppColors.goldAccent : const Color(0xFFFF9800),
                    icon: Icons.account_balance,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderColor),
            const SizedBox(height: 12),

            // Pasek narzędzi finansowych
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showPhysiologicalTestingDialog(
                      context: context,
                      save: save,
                      careerController: careerController,
                    ),
                    icon: const Icon(Icons.science, size: 15, color: Colors.cyanAccent),
                    label: const Text('Badania Wydolnościowe'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.cyanAccent,
                      side: BorderSide(color: Colors.cyanAccent.withAlpha(100)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEquipmentConsumablesDialog(
                      context: context,
                      save: save,
                      careerController: careerController,
                    ),
                    icon: const Icon(Icons.build_circle_outlined, size: 15, color: AppColors.goldAccent),
                    label: const Text('Materiały & Serwis'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.goldAccent,
                      side: BorderSide(color: AppColors.goldAccent.withAlpha(100)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    careerController.executeMonthlyFinancialSettlement();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text(
                          'Pomyślnie przeprowadzono comiesięczne rozliczenie finansowe klubu!',
                          style: TextStyle(color: AppColors.goldAccent),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 15, color: AppColors.textPrimary),
                  label: const Text('Rozlicz Miesiąc'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
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
  // MODAL SZCZEGÓŁOWEGO RAPORTU CASHFLOW
  // ===========================================================================

  void _showMonthlyCashflowDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        final report = careerController.getMonthlyCashflowReport() ??
            FinanceAndBudgetService.generateMonthlyCashflowReport(save: save);

        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Container(
            width: 880,
            height: 720,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nagłówek raportu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withAlpha(30),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.analytics, color: AppColors.goldAccent, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'RAPORT FINANSOWY I PRZEPŁYW GOTÓWKI (CASHFLOW)',
                              style: TextStyle(
                                color: AppColors.goldAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Okres: ${report.period.year}.${report.period.month.toString().padLeft(2, '0')} • ${save.playerTeam.name}',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Wskaźniki kondycji finansowej
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: report.isProfitable
                          ? const Color(0xFF4CAF50).withAlpha(100)
                          : const Color(0xFFE53935).withAlpha(100),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCashflowSummaryPill(
                        label: 'Stan konta',
                        value: '€${save.playerTeam.cashBalanceEur.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                        color: AppColors.goldAccent,
                      ),
                      _buildCashflowSummaryPill(
                        label: 'Bilans Netto',
                        value:
                            '${report.isProfitable ? '+' : ''}€${report.netCashflowEur.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                        color: report.isProfitable ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                      ),
                      _buildCashflowSummaryPill(
                        label: 'Płynność (Runway)',
                        value: '${report.runwayMonths.toStringAsFixed(1)} mies.',
                        color: report.runwayMonths > 6 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                      ),
                      _buildCashflowSummaryPill(
                        label: 'Ocena zdrowia klubu',
                        value: '${report.financialHealthScore} / 100',
                        color: report.financialHealthScore >= 70
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2 Kolumny: Przychody vs Wydatki
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEWA KOLUMNA: PRZYCHODY
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'PRZYCHODY (INCOMES)',
                                      style: TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '+€${report.totalIncomeEur.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                                      style: const TextStyle(
                                        color: Color(0xFF4CAF50),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: AppTheme.borderColor, height: 16),
                                _buildFinancialLineItem(
                                  title: 'Transze od sponsorów',
                                  amount: report.sponsorPayoutEur,
                                  isPositive: true,
                                  subtitle: '${save.playerTeam.sponsors.length} aktywnych umów sponsorskich',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Dotacja producenta rowerów',
                                  amount: report.bikeManufacturerCashEur,
                                  isPositive: true,
                                  subtitle: save.playerTeam.bikeDeal.manufacturerName,
                                ),
                                _buildFinancialLineItem(
                                  title: 'Nagrody z wyścigów (Udział klubu)',
                                  amount: report.prizeMoneyClubShareEur,
                                  isPositive: true,
                                  subtitle: 'Pula dla kolarzy: €${report.prizeMoneyRidersShareEur}',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Odstępne za zawodników (Klauzule)',
                                  amount: report.riderBuyoutIncomeEur,
                                  isPositive: true,
                                  subtitle: 'Wykupione kontrakty przez rywali',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Pozostałe przychody',
                                  amount: report.otherIncomeEur,
                                  isPositive: true,
                                  subtitle: 'Catering, prawa medialne, premie',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // PRAWA KOLUMNA: KOSZTY OPERACYJNE
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'KOSZTY OPERACYJNE (EXPENSES)',
                                      style: TextStyle(
                                        color: Color(0xFFE53935),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '-€${report.totalExpensesEur.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                                      style: const TextStyle(
                                        color: Color(0xFFE53935),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(color: AppTheme.borderColor, height: 16),
                                _buildFinancialLineItem(
                                  title: 'Pensje kolarzy',
                                  amount: report.riderSalariesEur,
                                  isPositive: false,
                                  subtitle: '${save.playerRoster.length} zawodników w zespole',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Wynagrodzenia sztabu',
                                  amount: report.staffSalariesEur,
                                  isPositive: false,
                                  subtitle: 'Dyrektorzy, lekarze, mechanicy, trenerzy',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Logistyka wyścigowa & Flota',
                                  amount: report.raceLogisticsEur,
                                  isPositive: false,
                                  subtitle: 'Autokar klubowy, wozy techniczne, przeloty i hotele',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Zgrupowania wysokogórskie',
                                  amount: report.trainingCampsEur,
                                  isPositive: false,
                                  subtitle: 'Obozy wysokościowe (Teide, Sierra Nevada)',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Badania wydolnościowe',
                                  amount: report.physiologicalTestingEur,
                                  isPositive: false,
                                  subtitle: 'Ergospirometria, mleczan, VO2max',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Serwis & Sprzęt eksploatacyjny',
                                  amount: report.equipmentServiceAndPurchasesEur,
                                  isPositive: false,
                                  subtitle: 'Szytki, łańcuchy, kasety, części zamienne',
                                ),
                                _buildFinancialLineItem(
                                  title: 'Infrastruktura i baza klubowa',
                                  amount: report.facilitiesMaintenanceEur,
                                  isPositive: false,
                                  subtitle: 'Service Course, tunel aero, centrum medyczne',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Rekomendacje zarządcze
                if (report.recommendations.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldAccent.withAlpha(80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates, color: AppColors.goldAccent, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: report.recommendations
                                .map((r) => Text('• $r', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11)))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCashflowSummaryPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildFinancialLineItem({
    required String title,
    required int amount,
    required bool isPositive,
    required String subtitle,
  }) {
    final formattedAmount =
        amount.abs().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : '-'}€$formattedAmount',
            style: TextStyle(
              color: isPositive ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // MODAL BADAŃ WYDOLNOŚCIOWYCH (ERGOSPIROMETRIA, MLECZAN)
  // ===========================================================================

  void _showPhysiologicalTestingDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    PhysiologicalTestType selectedTest = PhysiologicalTestType.ergospirometryVO2Max;
    final roster = save.playerRoster;
    final Set<String> selectedRiderIds = {if (roster.isNotEmpty) roster.first.id};

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stfCtx, setState) {
            final isFleet = selectedTest == PhysiologicalTestType.teamFleetScreening;
            final int totalCost = isFleet
                ? selectedTest.costPerRiderEur
                : selectedTest.costPerRiderEur * selectedRiderIds.length;
            final canAfford = save.playerTeam.cashBalanceEur >= totalCost;

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                width: 780,
                height: 680,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withAlpha(30),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.science, color: Colors.cyanAccent, size: 24),
                            ),
                            const SizedBox(width: 14),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LABORATORIUM WYDOLNOŚCIOWE & DIAGNOSTYKA',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Ergospirometria, kinetyka mleczanu, kalibracja FTP i wykrywanie przetrenowania',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Wybór rodzaju badania
                    const Text('Wybierz procedurę diagnostyczną:', style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        children: PhysiologicalTestType.values.map((type) {
                          final isSelected = selectedTest == type;
                          return InkWell(
                            onTap: () => setState(() => selectedTest = type),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.cyanAccent.withAlpha(25) : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                                border: isSelected ? Border.all(color: Colors.cyanAccent.withAlpha(120)) : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type.label,
                                          style: TextStyle(
                                            color: isSelected ? Colors.cyanAccent : AppColors.textPrimary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(type.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9)),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    type == PhysiologicalTestType.teamFleetScreening
                                        ? '€${type.costPerRiderEur} ryczałt'
                                        : '€${type.costPerRiderEur} / os.',
                                    style: const TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w800, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Wybór kolarzy (jeśli nie screening całej floty)
                    if (!isFleet) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Wybierz kolarzy do badania (${selectedRiderIds.length} zaznaczonych):', style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700)),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (selectedRiderIds.length == roster.length) {
                                  selectedRiderIds.clear();
                                } else {
                                  selectedRiderIds.addAll(roster.map((r) => r.id));
                                }
                              });
                            },
                            child: Text(selectedRiderIds.length == roster.length ? 'Odznacz wszystkich' : 'Zaznacz wszystkich', style: const TextStyle(fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: ListView.separated(
                          itemCount: roster.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (ctx, idx) {
                            final r = roster[idx];
                            final isChecked = selectedRiderIds.contains(r.id);

                            return CheckboxListTile(
                              value: isChecked,
                              dense: true,
                              tileColor: AppColors.surfaceLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: BorderSide(
                                  color: isChecked ? Colors.cyanAccent.withAlpha(80) : AppTheme.borderColor,
                                ),
                              ),
                              title: Text(
                                '${r.fullName} (${r.age} l.) • OVR: ${r.overallRating}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                'FTP: ${(r.powerProfile.watts20m * 0.95).toStringAsFixed(0)}W • ATL: ${r.physiology.acuteFatigueAtl.toStringAsFixed(0)} • Zmęczenie: ${r.physiology.trainingStressBalanceTsb.toStringAsFixed(0)} TSB',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedRiderIds.add(r.id);
                                  } else {
                                    selectedRiderIds.remove(r.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.groups, size: 48, color: Colors.cyanAccent),
                              const SizedBox(height: 12),
                              const Text('Pakiet Badań Całej Kadry (Fleet Screening)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text('Wszyscy ${roster.length} kolarze drużyny zostaną poddani pełnej diagnostyce ergospirometrycznej i mleczanowej.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 14),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 10),

                    // Podsumowanie kosztu i przycisk realizacji
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Łączny koszt badań:', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            Text(
                              '€${totalCost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                              style: TextStyle(
                                color: canAfford ? AppColors.goldAccent : const Color(0xFFE53935),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: (canAfford && (isFleet || selectedRiderIds.isNotEmpty))
                              ? () {
                                  Navigator.pop(dialogCtx);
                                  final outcome = careerController.conductPhysiologicalTesting(
                                    riderIds: isFleet ? roster.map((r) => r.id).toList() : selectedRiderIds.toList(),
                                    testType: selectedTest,
                                  );
                                  _showTestingOutcomeDialog(context, outcome);
                                }
                              : null,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Przeprowadź Badania'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showTestingOutcomeDialog(BuildContext context, PhysiologicalTestingOutcome outcome) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.cyanAccent),
          ),
          child: Container(
            width: 720,
            height: 580,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_turned_in, color: Colors.cyanAccent, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'OFICJALNE WYNIKI BADAŃ WYDOLNOŚCIOWYCH',
                          style: TextStyle(color: Colors.cyanAccent, fontSize: 15, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Przebadano ${outcome.results.length} kolarzy. Koszt: €${outcome.totalCostEur}. Parametry wydolnościowe i progi zaktualizowane.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: outcome.results.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final r = outcome.results[idx];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: r.isOvertrained ? const Color(0xFFE53935) : AppTheme.borderColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.riderName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                if (r.isOvertrained)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFE53935).withAlpha(30), borderRadius: BorderRadius.circular(4)),
                                    child: const Text('ALERT: PRZETRENOWANIE', style: TextStyle(color: Color(0xFFE53935), fontSize: 9, fontWeight: FontWeight.w800)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'VO2max: ${r.measuredVo2Max.toStringAsFixed(1)} ml/kg/min • Kalibrowane FTP: ${r.measuredFtpWatts.toStringAsFixed(0)}W • Próg mleczanowy: ${r.lactateThresholdWatts.toStringAsFixed(0)}W • HRmax: ${r.measuredMaxHeartRate} bpm',
                              style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(r.summary, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text('Rekomendacja: ${r.recommendation}', style: const TextStyle(color: AppColors.goldAccent, fontSize: 9, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                      child: const Text('Zamknij'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // MODAL PAKIETÓW MATERIAŁÓW EKSPLOATACYJNYCH I SERWISU
  // ===========================================================================

  void _showEquipmentConsumablesDialog({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Container(
            width: 700,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.build_circle_outlined, color: AppColors.goldAccent, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'SERWIS SPRZĘTU & PAKIETY EKSPLOATACYJNE',
                            style: TextStyle(color: AppColors.goldAccent, fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Dostępne pakiety części zamiennych i optymalizacji dla floty:', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 12),

                  ...FinanceAndBudgetService.availableEquipmentPackages.map((pkg) {
                    final canAfford = save.playerTeam.cashBalanceEur >= pkg.costEur;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(pkg.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(pkg.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                const SizedBox(height: 4),
                                Text('Korzyść: ${pkg.benefitDescription}', style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 9, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('€${pkg.costEur}', style: const TextStyle(color: AppColors.goldAccent, fontSize: 14, fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              ElevatedButton(
                                onPressed: canAfford
                                    ? () {
                                        Navigator.pop(dialogCtx);
                                        careerController.purchaseEquipmentPackage(pkg);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.surface,
                                            content: Text('Zakupiono pakiet: ${pkg.name}!', style: const TextStyle(color: AppColors.goldAccent)),
                                          ),
                                        );
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.goldAccent,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                                ),
                                child: const Text('Kup Pakiet'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBikeManufacturerAndAeroCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    final playerTeam = save.playerTeam;
    final deal = playerTeam.bikeDeal;
    final prowess = careerController.getTeamEquipmentProwessRating();
    final List<CompleteBike> bikes = playerTeam.inventoryBikes;

    final String prestigeStars = '★' * deal.prestigeLevel + '☆' * (5 - deal.prestigeLevel);

    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pedal_bike, size: 20, color: AppColors.goldAccent),
                    SizedBox(width: 8),
                    Text(
                      'SPRZĘT ROWEROWY I SPONSOR TECHNICZNY',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showWindTunnelCampaignDialog(context, save, careerController),
                      icon: const Icon(Icons.air, size: 15, color: AppColors.cyanAccent),
                      label: const Text('Tunel Aero (R&D)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.cyanAccent,
                        side: const BorderSide(color: AppColors.cyanAccent),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _showManufacturerNegotiationsDialog(context, save, careerController),
                      icon: const Icon(Icons.handshake, size: 15),
                      label: const Text('Negocjuj Umowę'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Karta aktualnego dostawcy rowerów
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.precision_manufacturing, color: AppColors.goldAccent, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deal.manufacturerName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    prestigeStars,
                                    style: const TextStyle(color: AppColors.goldAccent, fontSize: 11, letterSpacing: 1.5),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Prestiż: ${deal.prestigeLevel}/5 ★',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            deal.annualCashContributionEur > 0
                                ? '+€${(deal.annualCashContributionEur / 1000000).toStringAsFixed(2)}M / rok'
                                : 'Zakup ze Zniżką',
                            style: AppTheme.statNumberStyle(
                              fontSize: 14,
                              color: deal.annualCashContributionEur > 0 ? AppColors.powerZone3 : AppColors.goldAccent,
                            ),
                          ),
                          const Text(
                            'Wkład gotówkowy sponsora',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppTheme.borderColor, height: 1),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricMini('Pula Rowerów', '${deal.freeBikesQuota} maszyn'),
                      _buildMetricMini('Poziom R&D', '${deal.researchAndDevelopmentLevel}/100 pkt'),
                      _buildMetricMini('Czas Kontraktu', '${deal.contractYearsLeft} ${deal.contractYearsLeft == 1 ? "rok" : "lata"}'),
                      _buildMetricMini('Indeks Sprzętu', '${prowess.round()}/100 pkt'),
                    ],
                  ),
                ],
              ),
            ),
            if (bikes.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'AKTUALNA FLOTA RAM I MASZYN WYŚCIGOWYCH (INVENTORY):',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...bikes.map((bike) {
                final frame = bike.frame;
                String catLabel = 'SZOSA AERO';
                Color catColor = AppColors.cyanAccent;
                if (frame.category == FrameCategory.lightweightClimbing) {
                  catLabel = 'GÓRSKA';
                  catColor = AppColors.powerZone3;
                } else if (frame.category == FrameCategory.timeTrial) {
                  catLabel = 'CZASÓWKA TT';
                  catColor = AppColors.goldAccent;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Wektorowy profil 2D skonfigurowanego roweru
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: BikePreviewWidget(
                            bike: bike,
                            height: 100,
                            showBackground: true,
                            backgroundColor: const Color(0xFF0F1218),
                            showFloorReflection: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: catColor.withAlpha(40),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    catLabel,
                                    style: TextStyle(color: catColor, fontSize: 9, fontWeight: FontWeight.w800),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  frame.name,
                                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ],
                            ),
                            Text(
                              '${bike.totalWeightKg.toStringAsFixed(2)} kg • Stożek: ${bike.wheelset.isDiscWheel ? "Dysk TT" : "${bike.wheelset.rimDepthMm}mm"} • CdA: ${bike.totalCdaModifier.toStringAsFixed(4)} m²',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricMini(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }

  void _showManufacturerNegotiationsDialog(
    BuildContext context,
    CareerSave save,
    CareerController careerController,
  ) {
    final offers = careerController.getAvailableBikeManufacturerOffers();
    ManufacturerOfferOption selectedOffer = offers.first;
    ManufacturerDealTier selectedTier = selectedOffer.dealTier;
    int requestedCash = selectedOffer.annualCashContributionEur;
    int requestedBikes = selectedOffer.freeBikesQuota > 0 ? selectedOffer.freeBikesQuota : 24;
    double requestedDiscount = selectedOffer.discountRate > 0 ? selectedOffer.discountRate : 0.40;
    int contractYears = 2;
    bool windTunnelCommitment = true;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              title: const Row(
                children: [
                  Icon(Icons.pedal_bike, color: AppColors.goldAccent),
                  SizedBox(width: 10),
                  Text('Negocjacje ze Sponsorem Technicznym'),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Baner informacyjny realiów rynkowych
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.cyanAccent, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                save.playerTeam.division == TeamDivision.continental
                                    ? 'Dywizja Continental: Zespoły kupują ramy ze zniżką (30-55%) lub wybierają cięższe konstrukcje od mniejszych marek. Producenci 5★ nie sponsorują trzeciej ligi za darmo!'
                                    : (save.playerTeam.division == TeamDivision.proTeam
                                        ? 'Dywizja ProTeam: Producenci dostarczają pełne pule darmowych maszyn oraz umiarkowane dopłaty gotówkowe do budżetu (€200k - €750k).'
                                        : 'Dywizja WorldTour: Topowi producenci sami rywalizują o prawa techniczne, oferując 90-130 bezpłatnych maszyn i dopłacając miliony euro rocznie!'),
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Wybierz producenta rowerów:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<ManufacturerOfferOption>(
                        initialValue: selectedOffer,
                        dropdownColor: AppColors.surfaceLight,
                        isExpanded: true,
                        items: offers.map((o) {
                          final stars = '★' * o.brandPrestige;
                          return DropdownMenuItem(
                            value: o,
                            child: Text(
                              '${o.brandName} ($stars) • ${o.dealTier.label}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              selectedOffer = val;
                              selectedTier = val.dealTier;
                              requestedCash = val.annualCashContributionEur;
                              requestedBikes = val.freeBikesQuota > 0 ? val.freeBikesQuota : 24;
                              requestedDiscount = val.discountRate > 0 ? val.discountRate : 0.40;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      // Opis propozycji fabrycznej
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.goldAccent.withAlpha(60)),
                        ),
                        child: Text(
                          selectedOffer.pitchDescription,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // Formuła współpracy i czas trwania
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Formuła umowy:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<ManufacturerDealTier>(
                                  initialValue: selectedTier,
                                  dropdownColor: AppColors.surfaceLight,
                                  items: ManufacturerDealTier.values.map((t) {
                                    return DropdownMenuItem(value: t, child: Text(t.label, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => selectedTier = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 130,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Lata umowy:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<int>(
                                  initialValue: contractYears,
                                  dropdownColor: AppColors.surfaceLight,
                                  items: const [
                                    DropdownMenuItem(value: 1, child: Text('1 rok')),
                                    DropdownMenuItem(value: 2, child: Text('2 lata')),
                                    DropdownMenuItem(value: 3, child: Text('3 lata')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => contractYears = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (selectedTier == ManufacturerDealTier.factoryWorksSponsorship) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Żądana roczna dopłata gotówkowa:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            Text(
                              '€${(requestedCash / 1000000).toStringAsFixed(2)}M / rok',
                              style: AppTheme.statNumberStyle(fontSize: 14, color: AppColors.powerZone3),
                            ),
                          ],
                        ),
                        Slider(
                          value: requestedCash.toDouble(),
                          min: 0,
                          max: 4500000,
                          divisions: 18,
                          activeColor: AppColors.powerZone3,
                          onChanged: (val) {
                            setState(() => requestedCash = (val / 100000).round() * 100000);
                          },
                        ),
                      ] else if (selectedTier == ManufacturerDealTier.discountPurchase) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Proponowana zniżka flotowa:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            Text(
                              '${(requestedDiscount * 100).round()}% zniżki',
                              style: AppTheme.statNumberStyle(fontSize: 14, color: AppColors.goldAccent),
                            ),
                          ],
                        ),
                        Slider(
                          value: requestedDiscount,
                          min: 0.20,
                          max: 0.60,
                          divisions: 8,
                          activeColor: AppColors.goldAccent,
                          onChanged: (val) {
                            setState(() => requestedDiscount = val);
                          },
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Liczba rowerów w puli:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          Text(
                            '$requestedBikes maszyn',
                            style: AppTheme.statNumberStyle(fontSize: 14, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      Slider(
                        value: requestedBikes.toDouble(),
                        min: 15,
                        max: 130,
                        divisions: 23,
                        activeColor: AppColors.primaryAccent,
                        onChanged: (val) {
                          setState(() => requestedBikes = val.round());
                        },
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.primaryAccent,
                        title: const Text(
                          'Zobowiązanie do wspólnych badań w tunelu aerodynamicznym R&D',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Podnosi atrakcyjność oferty dla producenta o +15%',
                          style: TextStyle(fontSize: 10, color: AppColors.cyanAccent),
                        ),
                        value: windTunnelCommitment,
                        onChanged: (val) {
                          if (val != null) setState(() => windTunnelCommitment = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final proposal = ManufacturerNegotiationProposal(
                      brandId: selectedOffer.brandId,
                      requestedDealTier: selectedTier,
                      contractYears: contractYears,
                      requestedAnnualCashEur: requestedCash,
                      requestedBikesCount: requestedBikes,
                      proposedPurchaseDiscountRate: requestedDiscount,
                      windTunnelCommitment: windTunnelCommitment,
                    );

                    Navigator.pop(dialogCtx);

                    final result = careerController.submitBikeManufacturerProposal(proposal);
                    _showManufacturerResultDialog(context, result, careerController, selectedOffer);
                  },
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Złóż Ofertę Producentowi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showManufacturerResultDialog(
    BuildContext context,
    ManufacturerNegotiationResult result,
    CareerController careerController,
    ManufacturerOfferOption offer,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        Color statusColor;
        String statusTitle;
        IconData statusIcon;

        if (result.isAccepted) {
          statusColor = AppColors.powerZone3;
          statusTitle = 'OFERTA ZAAKCEPTOWANA!';
          statusIcon = Icons.check_circle;
        } else if (result.isCounterOffer) {
          statusColor = AppColors.goldAccent;
          statusTitle = 'KONTROFERTA PRODUCENTA';
          statusIcon = Icons.swap_horiz;
        } else {
          statusColor = AppColors.powerZone6;
          statusTitle = 'OFERTA ODRZUCONA';
          statusIcon = Icons.cancel;
        }

        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: statusColor.withAlpha(120)),
          ),
          title: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      'Dyrekcja Handlowa ${offer.brandName}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote, color: AppColors.goldAccent, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.commercialDirectorQuote,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OCENA PUNKTOWA NEGOCJACJI SPRZĘTOWYCH:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                _buildScoreBar('Dopasowanie do Dywizji', result.divisionFitScore, 35.0, AppColors.cyanAccent),
                const SizedBox(height: 6),
                _buildScoreBar('Prestiż i Punkty UCI Zespołu', result.teamPrestigeScore, 30.0, AppColors.goldAccent),
                const SizedBox(height: 6),
                _buildScoreBar('Realizm Finansowy Propozycji', result.financialRealismScore, 25.0, AppColors.powerZone4),
                const SizedBox(height: 6),
                _buildScoreBar('Synergia Badań Aerodynamicznych R&D', result.rdSynergyScore, 10.0, AppColors.primaryAccent),
                const Divider(color: AppTheme.borderColor, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ŁĄCZNA NOTA PRODUCENTA:', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    Text(
                      '${result.overallScore.toStringAsFixed(1)} / 100 pkt',
                      style: AppTheme.statNumberStyle(fontSize: 16, color: statusColor),
                    ),
                  ],
                ),
                if (result.resultingDeal != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.goldAccent.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.resultingDeal!.annualCashContributionEur > 0
                                  ? 'Dopłata do budżetu:'
                                  : 'Koszt zakupu floty:',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.resultingDeal!.annualCashContributionEur > 0
                                  ? '+€${(result.resultingDeal!.annualCashContributionEur / 1000000).toStringAsFixed(2)}M / rok'
                                  : '€${(result.finalPurchaseCostEur / 1000).round()}k',
                              style: AppTheme.statNumberStyle(
                                fontSize: 15,
                                color: result.resultingDeal!.annualCashContributionEur > 0
                                    ? AppColors.powerZone3
                                    : AppColors.goldAccent,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Pula rowerów:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              '${result.resultingDeal!.freeBikesQuota} maszyn',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text(result.resultingDeal != null ? 'Odrzuć' : 'Zamknij'),
            ),
            if (result.resultingDeal != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  careerController.acceptBikeManufacturerDeal(
                    deal: result.resultingDeal!,
                    dealTier: result.resultingDealTier,
                    initialPurchaseCostEur: result.finalPurchaseCostEur,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surface,
                      content: Text(
                        'Pomyślnie podpisano umowę z ${offer.brandName}! Nowa flota rowerów wyścigowych trafiła do Service Course.',
                        style: const TextStyle(color: AppColors.goldAccent),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Podpisz Kontrakt i Odbierz Flotę'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.powerZone3,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  void _showWindTunnelCampaignDialog(
    BuildContext context,
    CareerSave save,
    CareerController careerController,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: const Row(
            children: [
              Icon(Icons.air, color: AppColors.cyanAccent),
              SizedBox(width: 10),
              Text('Wspólne Testy w Tunelu Aerodynamicznym R&D'),
            ],
          ),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.speed, color: AppColors.goldAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Wspólne sesje z ${save.playerTeam.bikeDeal.manufacturerName} trwale obniżają opór CdA ram i kasków oraz masę sprzętu na kolejny sezon. Każde -0.0100 CdA daje ponad 10 Watów zysku przy 45 km/h!',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...WindTunnelCampaignType.values.map((camp) {
                    final bool hasFacilityLevel = save.windTunnelLevel >= camp.minWindTunnelLevel;
                    final bool hasBudget = save.playerCashBalanceEur >= camp.baseCostEur;
                    final bool canLaunch = hasFacilityLevel && hasBudget;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: canLaunch ? AppColors.cyanAccent.withAlpha(80) : AppTheme.borderColor,
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
                                    camp.title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                Text(
                                  '€${(camp.baseCostEur / 1000).round()}k • ${camp.durationDays} dni',
                                  style: AppTheme.statNumberStyle(fontSize: 13, color: AppColors.goldAccent),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              camp.description,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.cyanAccent.withAlpha(30),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'CdA: -${(camp.cdaReduction * 1000).toStringAsFixed(1)} mCdA',
                                        style: const TextStyle(color: AppColors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    if (camp.weightReductionGrams > 0) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.powerZone3.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Waga: -${camp.weightReductionGrams}g',
                                          style: const TextStyle(color: AppColors.powerZone3, fontSize: 10, fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: canLaunch
                                      ? () {
                                          Navigator.pop(dialogCtx);
                                          final report = careerController.conductWindTunnelTest(camp);
                                          _showWindTunnelReportDialog(context, report);
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.cyanAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                  ),
                                  child: Text(
                                    !hasFacilityLevel
                                        ? 'Wymaga Tunelu Lv.${camp.minWindTunnelLevel}'
                                        : (!hasBudget ? 'Brak środków' : 'Rozpocznij Badania'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  void _showWindTunnelReportDialog(
    BuildContext context,
    WindTunnelTestReport report,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cyanAccent),
          ),
          title: const Row(
            children: [
              Icon(Icons.verified, color: AppColors.cyanAccent, size: 28),
              SizedBox(width: 10),
              Text('Raport z Tunelu Aerodynamicznego'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote, color: AppColors.cyanAccent, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.chiefAerodynamicistQuote,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'OSIĄGNIĘTE PARAMETRY FIZYCZNE RAM:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricMini('Redukcja Oporu CdA', '${(report.cdaDelta * 1000).toStringAsFixed(1)} mCdA'),
                    _buildMetricMini('Redukcja Wagi', '${report.weightDeltaGrams} gramów'),
                    _buildMetricMini('Koszt Kampanii', '€${(report.costEur / 1000).round()}k'),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'ZMODYFIKOWANE RAMY WE FLOCIE ZESPOŁU:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                ...report.upgradedFrameNames.map((name) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• $name',
                      style: const TextStyle(color: AppColors.cyanAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Zatwierdź i Zamknij'),
            ),
          ],
        );
      },
    );
  }

  void _showAltitudeCampSelectionDialog(
    BuildContext context,
    CareerSave save,
    CareerController careerController,
  ) {
    final locations = careerController.getAvailableAltitudeCampLocations();
    AltitudeCampLocation selectedLocation = locations.first;
    int durationDays = 14;
    final Set<String> selectedRiderIds = save.playerRoster.take(8).map((r) => r.id).toSet();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final int totalCost = selectedLocation.costPerRiderPerDayEur * selectedRiderIds.length * durationDays;
            final bool hasEnoughBudget = save.playerCashBalanceEur >= totalCost;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              title: const Row(
                children: [
                  Icon(Icons.terrain, color: AppColors.goldAccent),
                  SizedBox(width: 10),
                  Text('Zgrupowanie Wysokogórskie (Altitude Camp)'),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.air, color: AppColors.cyanAccent, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Trening w hipoksji powyżej 1800m stymuluje produkcję erytropoetyny (EPO), zwiększa masę hemoglobiny i podnosi VO2max przed Grand Tourem. Obóz drastycznie podnosi chwilowe zmęczenie (ATL) – zaplanuj 5-7 dni taperingu przed startem wyścigu!',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Wybierz bazę wysokogórską:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<AltitudeCampLocation>(
                        initialValue: selectedLocation,
                        dropdownColor: AppColors.surfaceLight,
                        isExpanded: true,
                        items: locations.map((loc) {
                          return DropdownMenuItem(
                            value: loc,
                            child: Text(
                              '${loc.name} (${loc.altitudeMeters} m n.p.m.) • €${loc.costPerRiderPerDayEur}/osobodzień',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedLocation = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.goldAccent.withAlpha(60)),
                        ),
                        child: Text(
                          selectedLocation.description,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Czas trwania obozu:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                          DropdownButton<int>(
                            value: durationDays,
                            dropdownColor: AppColors.surfaceLight,
                            items: const [
                              DropdownMenuItem(value: 7, child: Text('7 dni (Krótki blok)')),
                              DropdownMenuItem(value: 10, child: Text('10 dni (Średni blok)')),
                              DropdownMenuItem(value: 14, child: Text('14 dni (Pełna adaptacja)')),
                              DropdownMenuItem(value: 21, child: Text('21 dni (Grand Tour Peak)')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => durationDays = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Wybierz kolarzy na obóz (${selectedRiderIds.length}/${save.playerRoster.length}):',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                if (selectedRiderIds.length == save.playerRoster.length) {
                                  selectedRiderIds.clear();
                                } else {
                                  selectedRiderIds.addAll(save.playerRoster.map((r) => r.id));
                                }
                              });
                            },
                            child: Text(
                              selectedRiderIds.length == save.playerRoster.length ? 'Odznacz' : 'Zaznacz Wszystkich',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        height: 170,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: ListView.separated(
                          itemCount: save.playerRoster.length,
                          separatorBuilder: (_, __) => const Divider(color: AppTheme.borderColor, height: 1),
                          itemBuilder: (ctx, idx) {
                            final r = save.playerRoster[idx];
                            final isChecked = selectedRiderIds.contains(r.id);
                            final double cp = r.physiology.criticalPowerWatts.toDouble();
                            final double wKg = cp / r.physiology.weightKg;

                            return CheckboxListTile(
                              dense: true,
                              activeColor: AppColors.primaryAccent,
                              title: Text(
                                '${r.fullName} (${wKg.toStringAsFixed(1)} W/kg, VO2: ${r.physiology.vo2Max.toStringAsFixed(1)})',
                                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                              ),
                              subtitle: Text(
                                '${r.specialization.name} • ATL: ${r.health.acuteTrainingLoad.round()}',
                                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                              ),
                              value: isChecked,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    selectedRiderIds.add(r.id);
                                  } else {
                                    selectedRiderIds.remove(r.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: hasEnoughBudget ? AppColors.powerZone3.withAlpha(80) : Colors.red),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Koszt zgrupowania:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  '€${totalCost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ')}',
                                  style: AppTheme.statNumberStyle(
                                    fontSize: 16,
                                    color: hasEnoughBudget ? AppColors.goldAccent : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Dostępny budżet:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const SizedBox(height: 2),
                                Text(
                                  '€${(save.playerCashBalanceEur / 1000000).toStringAsFixed(2)}M',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton.icon(
                  onPressed: (hasEnoughBudget && selectedRiderIds.isNotEmpty)
                      ? () {
                          Navigator.pop(dialogCtx);
                          final outcome = careerController.conductAltitudeTrainingCamp(
                            location: selectedLocation,
                            riderIds: selectedRiderIds.toList(),
                            durationDays: durationDays,
                          );
                          _showAltitudeCampOutcomeDialog(context, outcome);
                        }
                      : null,
                  icon: const Icon(Icons.flight_takeoff, size: 16),
                  label: const Text('Wyślij na Obóz Wysokogórski'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAltitudeCampOutcomeDialog(
    BuildContext context,
    AltitudeCampOutcome outcome,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.goldAccent),
          ),
          title: Row(
            children: [
              const Icon(Icons.medical_services, color: AppColors.goldAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('RAPORT MEDYCZNY ZGGRUPOWANIA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(
                      '${outcome.campName} (${outcome.altitudeMeters} m n.p.m. • ${outcome.durationDays} dni)',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote, color: AppColors.goldAccent, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            outcome.doctorMedicalReport,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ŚREDNIE PRZYROSTY FIZJOLOGICZNE KADRY:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricMini('Średni Wzrost FTP', '+${outcome.averageFtpGainWatts.toStringAsFixed(1)} W'),
                      _buildMetricMini('Wzrost VO2max', '+${outcome.averageVo2maxGain.toStringAsFixed(2)} ml/kg'),
                      _buildMetricMini('Zmęczenie ATL', '+${outcome.averageAtlFatigueAdded.round()} pkt (Tapering)'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'STATUS KOLARZY PO ZGRUPOWANIU:',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  ...outcome.updatedRiders.map((r) {
                    final double cp = r.physiology.criticalPowerWatts.toDouble();
                    final double wKg = cp / r.physiology.weightKg;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '• ${r.fullName}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'FTP: ${cp.round()}W (${wKg.toStringAsFixed(2)} W/kg) • VO2: ${r.physiology.vo2Max.toStringAsFixed(1)}',
                            style: const TextStyle(color: AppColors.goldAccent, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Zatwierdź i Rozpocznij Tapering'),
            ),
          ],
        );
      },
    );
  }

  void _showRiderTrainingPlanDialog(
    BuildContext context,
    CareerSave save,
    Rider rider,
    CareerController careerController,
  ) {
    RiderTrainingFocus selectedFocus = RiderTrainingFocus.ftpDevelopment;
    TrainingIntensity selectedIntensity = TrainingIntensity.moderate;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final double cp = rider.physiology.criticalPowerWatts.toDouble();
            final double wKg = cp / rider.physiology.weightKg;

            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              title: Row(
                children: [
                  RiderAvatarWidget.fromRider(
                    rider: rider,
                    team: save.playerTeam,
                    size: 42,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Plan Treningowy: ${rider.fullName}'),
                        Text(
                          '${rider.specialization.name} • ${rider.age} lat • Potencjał: ${rider.potential}/100',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricMini('Moc Progowa (FTP)', '${cp.round()} W (${wKg.toStringAsFixed(2)} W/kg)'),
                                _buildMetricMini('Pułap VO2max', '${rider.physiology.vo2Max.toStringAsFixed(1)} ml/kg'),
                                _buildMetricMini('Sprint 5s', '${rider.powerProfile.watts5s} W'),
                              ],
                            ),
                            const Divider(color: AppTheme.borderColor, height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMetricMini('Baza (CTL)', '${rider.health.chronicTrainingLoad.round()} pkt'),
                                _buildMetricMini('Zmęczenie (ATL)', '${rider.health.acuteTrainingLoad.round()} pkt'),
                                _buildMetricMini('Świeżość (TSB)', '${rider.health.trainingStressBalance.round()} pkt'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Kierunek adaptacji treningowej:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<RiderTrainingFocus>(
                        initialValue: selectedFocus,
                        dropdownColor: AppColors.surfaceLight,
                        isExpanded: true,
                        items: RiderTrainingFocus.values.map((f) {
                          return DropdownMenuItem(
                            value: f,
                            child: Text(f.label, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedFocus = val);
                        },
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.goldAccent.withAlpha(60)),
                        ),
                        child: Text(
                          selectedFocus.description,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, height: 1.3),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Intensywność cyklu treningowego:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<TrainingIntensity>(
                        initialValue: selectedIntensity,
                        dropdownColor: AppColors.surfaceLight,
                        items: TrainingIntensity.values.map((i) {
                          return DropdownMenuItem(
                            value: i,
                            child: Text(i.label, style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedIntensity = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Anuluj'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogCtx);
                    careerController.setRiderTrainingFocus(
                      riderId: rider.id,
                      focus: selectedFocus,
                      intensity: selectedIntensity,
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text(
                          'Nowy plan treningowy (${selectedFocus.label}) aktywowany dla ${rider.fullName}!',
                          style: const TextStyle(color: AppColors.goldAccent),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Zastosuj Plan Treningowy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCommunityModdingCard({
    required BuildContext context,
    required CareerSave save,
    required CareerController careerController,
  }) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.public, size: 18, color: AppColors.goldAccent),
                    SizedBox(width: 8),
                    Text(
                      'SPOŁECZNOŚĆ & REAL NAME PACK',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                FutureBuilder<bool>(
                  future: careerController.hasDefaultModPreset(),
                  builder: (ctx, snapshot) {
                    final hasDefault = snapshot.data ?? false;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: hasDefault
                            ? AppColors.powerZone3.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: hasDefault ? AppColors.powerZone3 : AppTheme.borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasDefault ? Icons.check_circle : Icons.info_outline,
                            size: 12,
                            color: hasDefault ? AppColors.powerZone3 : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasDefault ? 'Preset domyślny: Aktywny' : 'Preset domyślny: Brak',
                            style: TextStyle(
                              color: hasDefault ? AppColors.powerZone3 : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Zastąp fikcyjne nazwy autentycznymi danymi: prawdziwi kolarze (Pogačar, Vingegaard, Evenepoel), '
              'oficjalne barwy strojów WorldTour, Grand Toury (Tour de France, Giro, Vuelta) oraz rowery (Colnago, Cervélo, Specialized, Pinarello).',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final outcome = await careerController.applySampleRealNamePack();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle, color: AppColors.goldAccent, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    outcome.summary,
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.powerZone6,
                            content: Text('Błąd aplikacji Real Name Pack: $e'),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.flash_on, size: 16),
                  label: const Text('Wczytaj Real Name Pack 2026 (1-klik)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    foregroundColor: Colors.black,
                    textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showModManagerDialog(
                    context,
                    careerController,
                    hasActiveSave: true,
                  ),
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Centrum Modów (Wklej JSON / Eksport)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showModManagerDialog(
    BuildContext context,
    CareerController careerController, {
    required bool hasActiveSave,
  }) {
    final textController = TextEditingController();
    bool setAsDefaultPreset = false;

    // Początkowo wklejamy domyślny przykładowy pakiet 2026 WorldTour
    textController.text = careerController.generateSampleRealNamePackJson();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final validation = careerController.validateModJson(textController.text);

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.public, color: AppColors.goldAccent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'CENTRUM MODÓW & REAL NAME PACK',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Wklej zawartość pliku JSON z modyfikacją stworzoną przez społeczność lub wygeneruj oficjalny Real Name Pack.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),

                    // Pasek akcji
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              textController.text =
                                  careerController.generateSampleRealNamePackJson();
                            });
                          },
                          icon: const Icon(Icons.auto_fix_high, size: 14),
                          label: const Text('Wstaw wzorzec Real Name Pack 2026'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.goldAccent,
                            side: const BorderSide(color: AppColors.goldAccent),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (hasActiveSave)
                          OutlinedButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                textController.text =
                                    careerController.exportCurrentWorldAsModJson();
                              });
                            },
                            icon: const Icon(Icons.file_upload_outlined, size: 14),
                            label: const Text('Eksportuj aktualny świat do JSON'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.cyanAccent,
                              side: const BorderSide(color: AppColors.cyanAccent),
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              textController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear, size: 14),
                          label: const Text('Wyczyść'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppTheme.borderColor),
                            textStyle: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Pole tekstowe z kodem JSON
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: validation.isValid ? AppTheme.borderColor : AppColors.powerZone6,
                          ),
                        ),
                        child: TextField(
                          controller: textController,
                          maxLines: null,
                          expands: true,
                          onChanged: (_) => setDialogState(() {}),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Wklej tutaj kod JSON modyfikacji...',
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Podsumowanie walidacji
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: validation.isValid ? AppColors.powerZone3 : AppColors.powerZone6,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                validation.isValid ? Icons.check_circle : Icons.error,
                                size: 16,
                                color: validation.isValid ? AppColors.powerZone3 : AppColors.powerZone6,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                validation.isValid
                                    ? 'Struktura poprawna (gotowa do zaaplikowania)'
                                    : 'Błędy walidacji schematu JSON (${validation.errors.length})',
                                style: TextStyle(
                                  color: validation.isValid ? AppColors.powerZone3 : AppColors.powerZone6,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Drużyny: ${validation.totalTeamsInMod} • Kolarze: ${validation.totalRidersInMod} • Wyścigi: ${validation.totalRacesInMod} • Rowery: ${validation.totalBikesInMod}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                          if (validation.errors.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              validation.errors.first.message,
                              style: const TextStyle(color: AppColors.powerZone6, fontSize: 11),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Opcja zapisu jako domyślny preset
                    Row(
                      children: [
                        Checkbox(
                          value: setAsDefaultPreset,
                          activeColor: AppColors.goldAccent,
                          checkColor: Colors.black,
                          onChanged: (val) {
                            setDialogState(() {
                              setAsDefaultPreset = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Zapisz jako domyślny preset dla nowych karier (plik default_real_name_pack.json)',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Przyciski akcji na dole okna
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Zamknij'),
                        ),
                        const SizedBox(width: 8),
                        if (hasActiveSave)
                          ElevatedButton.icon(
                            onPressed: !validation.isValid
                                ? null
                                : () async {
                                    try {
                                      final outcome =
                                          await careerController.applyModFromJson(textController.text);

                                      if (setAsDefaultPreset) {
                                        final package = await CustomModImporterService.importModFromBytes(
                                          utf8.encode(textController.text),
                                        );
                                        await careerController.saveModAsDefaultWorld(package);
                                      }

                                      if (dialogCtx.mounted) {
                                        Navigator.pop(dialogCtx);
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.surface,
                                            content: Row(
                                              children: [
                                                const Icon(Icons.check_circle, color: AppColors.goldAccent),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    outcome.summary,
                                                    style: const TextStyle(
                                                      color: AppColors.textPrimary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.powerZone6,
                                            content: Text('Błąd aplikacji modu: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Zastosuj do tej kariery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldAccent,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        if (!hasActiveSave)
                          ElevatedButton.icon(
                            onPressed: !validation.isValid
                                ? null
                                : () async {
                                    try {
                                      final package = await CustomModImporterService.importModFromBytes(
                                        utf8.encode(textController.text),
                                      );
                                      await careerController.saveModAsDefaultWorld(package);

                                      if (dialogCtx.mounted) {
                                        Navigator.pop(dialogCtx);
                                      }

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.surface,
                                            content: Text(
                                              'Zapisano mod "${package.metadata.name}" jako domyślny preset dla nowych gier!',
                                              style: const TextStyle(color: AppColors.goldAccent),
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.powerZone6,
                                            content: Text('Błąd zapisu presetu: $e'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.save, size: 16),
                            label: const Text('Zapisz jako domyślny preset'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldAccent,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSaveSlotsManagerDialog(
    BuildContext context,
    CareerController careerController, {
    required bool hasActiveSave,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final uiState = ref.watch(careerProvider);
            final slots = uiState.slots;
            final autoSlot = uiState.autoSaveSlot;

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 780, maxHeight: 700),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek okna
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.folder_shared_outlined, color: AppColors.goldAccent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'ZARZĄDZANIE STANEM GRY (5 SLOTÓW & AUTO-SAVE)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Wybierz slot do zapisu lub wczytania stanu kariery. System automatycznie zapisuje postępy (Auto-Save) po każdym zakończonym dniu w kalendarzu.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),

                    // Górny pasek akcji
                    Wrap(
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showImportSaveDialog(context, careerController),
                          icon: const Icon(Icons.file_download_outlined, size: 15, color: AppColors.cyanAccent),
                          label: const Text('Importuj Zapis (Z pliku / Schowka)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.cyanAccent,
                            side: const BorderSide(color: AppColors.cyanAccent),
                            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (hasActiveSave) ...[
                          ElevatedButton.icon(
                            onPressed: () async {
                              await careerController.saveCurrentGame();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.surface,
                                    content: Text(
                                      'Pomyślnie wykonano szybki zapis aktywnej kariery!',
                                      style: TextStyle(color: AppColors.goldAccent),
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.save, size: 15),
                            label: const Text('Szybki Zapis'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldAccent,
                              foregroundColor: Colors.black,
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showExportSaveDialog(
                              context,
                              careerController,
                              uiState.activeSlotNumber ?? 1,
                            ),
                            icon: const Icon(Icons.file_upload_outlined, size: 15),
                            label: const Text('Eksportuj Aktywny Zapis'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppTheme.borderColor),
                              textStyle: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 10),

                    // Lista slotów
                    Expanded(
                      child: ListView(
                        children: [
                          // 1. Sloty 1 - 5
                          const Text(
                            'SLOTY ZAPISU GRACZA (1 - 5):',
                            style: TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          for (int slotNum = 1; slotNum <= SaveGameManager.maxUserSlots; slotNum++) ...[
                            _buildSlotTile(
                              context: context,
                              dialogCtx: dialogCtx,
                              careerController: careerController,
                              slot: slots.firstWhere(
                                (s) => s.slotNumber == slotNum,
                                orElse: () => SaveSlotInfo.empty(slotNum),
                              ),
                              hasActiveSave: hasActiveSave,
                              isActiveSlot: uiState.activeSlotNumber == slotNum,
                            ),
                            const SizedBox(height: 8),
                          ],

                          const SizedBox(height: 12),
                          const Divider(color: AppTheme.borderColor),
                          const SizedBox(height: 8),

                          // 2. Slot Auto-Save
                          const Text(
                            'AUTOMATYCZNY ZAPIS PO DNIACH KALENDARZA (AUTO-SAVE):',
                            style: TextStyle(
                              color: AppColors.cyanAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),

                          _buildAutoSaveTile(
                            context: context,
                            dialogCtx: dialogCtx,
                            careerController: careerController,
                            autoSlot: autoSlot,
                            isActiveSlot: uiState.activeSlotNumber == 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSlotTile({
    required BuildContext context,
    required BuildContext dialogCtx,
    required CareerController careerController,
    required SaveSlotInfo slot,
    required bool hasActiveSave,
    required bool isActiveSlot,
  }) {
    if (!slot.isOccupied) {
      // Pusty slot
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Text(
                'SLOT ${slot.slotNumber}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Pusty slot zapisu',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            if (hasActiveSave)
              ElevatedButton.icon(
                onPressed: () async {
                  await careerController.saveToSlot(slot.slotNumber);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text(
                          'Pomyślnie zapisano karierę w slocie #${slot.slotNumber}!',
                          style: const TextStyle(color: AppColors.goldAccent),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_outlined, size: 14),
                label: Text('Zapisz w slocie #${slot.slotNumber}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NewCareerSetupScreen(
                        initialSlotNumber: slot.slotNumber,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Nowa gra w tym slocie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.goldAccent,
                  side: const BorderSide(color: AppColors.goldAccent),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
          ],
        ),
      );
    }

    // Zajęty slot
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isActiveSlot ? AppColors.goldAccent.withValues(alpha: 0.08) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActiveSlot ? AppColors.goldAccent : AppTheme.borderColor,
          width: isActiveSlot ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActiveSlot ? AppColors.goldAccent : AppColors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActiveSlot ? AppColors.goldAccent : AppTheme.borderColor,
                  ),
                ),
                child: Text(
                  'SLOT ${slot.slotNumber}',
                  style: TextStyle(
                    color: isActiveSlot ? Colors.black : AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isActiveSlot) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.powerZone3.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.powerZone3),
                  ),
                  child: const Text(
                    'AKTYWNA GRA',
                    style: TextStyle(
                      color: AppColors.powerZone3,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                'Zapis: ${slot.formattedLastSavedAt} (${slot.formattedFileSize})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (slot.playerTeamJerseyPrimaryHex != null) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _parseHexColor(slot.playerTeamJerseyPrimaryHex!),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                slot.playerTeamName ?? 'Brak nazwy',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${slot.playerManagerName ?? ''}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Sezon ${slot.currentSeasonYear ?? 2026} • ${slot.formattedDate}',
                style: const TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                slot.formattedCashBalance,
                style: const TextStyle(
                  color: AppColors.powerZone3,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showExportSaveDialog(context, careerController, slot.slotNumber),
                icon: const Icon(Icons.ios_share, size: 13),
                label: const Text('Eksportuj'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyanAccent,
                  side: const BorderSide(color: AppColors.cyanAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.powerZone6),
                tooltip: 'Usuń slot #${slot.slotNumber}',
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      backgroundColor: AppColors.surface,
                      title: Text('Usunąć Slot #${slot.slotNumber}?'),
                      content: Text('Czy na pewno chcesz bezpowrotnie usunąć zapis "${slot.saveName}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Anuluj')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(c, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.powerZone6),
                          child: const Text('Usuń'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await careerController.deleteSlot(slot.slotNumber);
                  }
                },
              ),
              if (hasActiveSave) ...[
                const SizedBox(width: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    await careerController.saveToSlot(slot.slotNumber);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.surface,
                          content: Text(
                            'Zaktualizowano zapis w slocie #${slot.slotNumber}!',
                            style: const TextStyle(color: AppColors.goldAccent),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_outlined, size: 13),
                  label: const Text('Nadpisz'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    textStyle: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final ok = await careerController.loadFromSlot(slot.slotNumber);
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text(
                          'Wczytano karierę ze slotu #${slot.slotNumber} (${slot.playerTeamName})!',
                          style: const TextStyle(color: AppColors.goldAccent),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow, size: 14),
                label: const Text('Wczytaj Slot'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutoSaveTile({
    required BuildContext context,
    required BuildContext dialogCtx,
    required CareerController careerController,
    required SaveSlotInfo? autoSlot,
    required bool isActiveSlot,
  }) {
    if (autoSlot == null || !autoSlot.isOccupied) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Row(
          children: [
            Icon(Icons.sync_disabled, size: 18, color: AppColors.textSecondary),
            SizedBox(width: 10),
            Text(
              'Brak pliku Auto-Save. Utworzy się automatycznie po zakończeniu dnia wyścigowego.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cyanAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cyanAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.cyanAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.cyanAccent),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 12, color: AppColors.cyanAccent),
                    SizedBox(width: 4),
                    Text(
                      'AUTO-SAVE',
                      style: TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Zapisano: ${autoSlot.formattedLastSavedAt} (${autoSlot.formattedFileSize})',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                autoSlot.playerTeamName ?? 'Drużyna',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${autoSlot.playerManagerName ?? ''}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Text(
                'Dzień: ${autoSlot.formattedDate} (Sezon ${autoSlot.currentSeasonYear ?? 2026})',
                style: const TextStyle(color: AppColors.goldAccent, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showExportSaveDialog(context, careerController, 0),
                icon: const Icon(Icons.ios_share, size: 13),
                label: const Text('Eksportuj'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyanAccent,
                  side: const BorderSide(color: AppColors.cyanAccent),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final ok = await careerController.loadAutoSave();
                  if (ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.surface,
                        content: Text(
                          'Wczytano automatyczny zapis kariery (${autoSlot.playerTeamName})!',
                          style: const TextStyle(color: AppColors.cyanAccent),
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.restore, size: 14),
                label: const Text('Wczytaj Auto-Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showImportSaveDialog(BuildContext context, CareerController careerController) {
    final textController = TextEditingController();
    int selectedSlot = 1;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final validation = careerController.validatePortableSave(textController.text);

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 650, maxHeight: 580),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.file_download_outlined, color: AppColors.cyanAccent, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'IMPORT ZAPISU KARIERY (CROSS-PLATFORM)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Wklej tutaj zawartość przenośnego pliku zapisu wyeksportowanego z telefonu, Maca lub PC. Wybierz docelowy slot.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 14),

                    // Wybór slotu docelowego
                    Row(
                      children: [
                        const Text(
                          'Zapisz w slocie:',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 12),
                        for (int i = 1; i <= SaveGameManager.maxUserSlots; i++) ...[
                          ChoiceChip(
                            label: Text('Slot $i'),
                            selected: selectedSlot == i,
                            selectedColor: AppColors.goldAccent,
                            backgroundColor: AppColors.surfaceLight,
                            labelStyle: TextStyle(
                              color: selectedSlot == i ? Colors.black : AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() => selectedSlot = i);
                              }
                            },
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Pole tekstowe
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: validation.isValid ? AppTheme.borderColor : AppColors.powerZone6,
                          ),
                        ),
                        child: TextField(
                          controller: textController,
                          maxLines: null,
                          expands: true,
                          onChanged: (_) => setDialogState(() {}),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(12),
                            border: InputBorder.none,
                            hintText: 'Wklej tutaj dane pliku zapisu (JSON)...',
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Panel podglądu walidacji
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: validation.isValid ? AppColors.powerZone3 : AppColors.powerZone6,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            validation.isValid ? Icons.check_circle : Icons.error_outline,
                            size: 16,
                            color: validation.isValid ? AppColors.powerZone3 : AppColors.powerZone6,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              validation.isValid
                                  ? 'Zapis poprawny: ${validation.slotInfo?.playerTeamName ?? 'Drużyna'} • '
                                      '${validation.slotInfo?.playerManagerName ?? ''} • '
                                      '${validation.slotInfo?.formattedDate ?? ''}'
                                  : (validation.errorMessage ?? 'Wklej dane zapisu aby zweryfikować'),
                              style: TextStyle(
                                color: validation.isValid ? AppColors.powerZone3 : AppColors.powerZone6,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Przyciski
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Anuluj'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: !validation.isValid
                              ? null
                              : () async {
                                  try {
                                    await careerController.importPortableSave(
                                      dataString: textController.text,
                                      targetSlotNumber: selectedSlot,
                                    );

                                    if (dialogCtx.mounted) {
                                      Navigator.pop(dialogCtx);
                                    }

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.surface,
                                          content: Text(
                                            'Pomyślnie zaimportowano zapis do Slotu #$selectedSlot!',
                                            style: const TextStyle(color: AppColors.goldAccent),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          backgroundColor: AppColors.powerZone6,
                                          content: Text('Błąd importu zapisu: $e'),
                                        ),
                                      );
                                    }
                                  }
                                },
                          icon: const Icon(Icons.check, size: 16),
                          label: Text('Zaimportuj do Slotu #$selectedSlot'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldAccent,
                            foregroundColor: Colors.black,
                            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showExportSaveDialog(BuildContext context, CareerController careerController, int slotNumber) async {
    String exportJson = '';
    try {
      exportJson = await careerController.exportSlotAsPortableJson(slotNumber);
    } catch (e) {
      exportJson = 'Błąd eksportu: $e';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 650, maxHeight: 560),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.ios_share, color: AppColors.cyanAccent, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          slotNumber == 0
                              ? 'EKSPORT AUTO-SAVE (CROSS-PLATFORM)'
                              : 'EKSPORT ZAPISU - SLOT #$slotNumber',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Skopiuj poniższy kod tekstowy i wklej na innym urządzeniu (telefon, tablet, Mac, PC), aby kontynuować karierę.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: TextField(
                      controller: TextEditingController(text: exportJson),
                      readOnly: true,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Zamknij'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: exportJson));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: AppColors.goldAccent, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Skopiowano kod zapisu kariery do schowka!',
                                  style: TextStyle(color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Kopiuj do schowka'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: Colors.black,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInboxDialog(BuildContext context, CareerStateNotifier notifier) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final careerState = ref.watch(careerStateNotifierProvider);
            final messages = careerState.inboxMessages;

            return Dialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 720, maxHeight: 650),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nagłówek
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.mail, color: AppColors.goldAccent, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'SKRZYNKA ODBIORCZA (INBOX)',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Oficjalne meldunki od lekarza zespołu, dyrektora sportowego przed etapami, raporty finansowe CFO i wiadomości od sponsora.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 12),

                    // Pasek akcji
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wszystkich wiadomości: ${messages.length} (${careerState.unreadMessagesCount} nieprzeczytanych)',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                        if (careerState.unreadMessagesCount > 0)
                          TextButton.icon(
                            onPressed: () => notifier.markAllMessagesAsRead(),
                            icon: const Icon(Icons.done_all, size: 14),
                            label: const Text('Oznacz wszystkie jako przeczytane'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.cyanAccent,
                              textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: AppTheme.borderColor),
                    const SizedBox(height: 8),

                    // Lista wiadomości
                    Expanded(
                      child: messages.isEmpty
                          ? const Center(
                              child: Text(
                                'Brak wiadomości w skrzynce odbiorczej.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              itemCount: messages.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final msg = messages[idx];
                                final bool isUrgent = msg.priority == InboxPriority.urgent;

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: msg.isRead
                                        ? AppColors.surfaceLight.withValues(alpha: 0.3)
                                        : AppColors.surfaceLight,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: !msg.isRead
                                          ? (isUrgent ? AppColors.powerZone6 : AppColors.goldAccent)
                                          : AppTheme.borderColor,
                                      width: !msg.isRead ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (!msg.isRead) ...[
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: isUrgent ? AppColors.powerZone6 : AppColors.goldAccent,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                          ],
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.background,
                                              borderRadius: BorderRadius.circular(4),
                                              border: Border.all(color: AppTheme.borderColor),
                                            ),
                                            child: Text(
                                              msg.category.label,
                                              style: TextStyle(
                                                color: isUrgent ? AppColors.powerZone6 : AppColors.goldAccent,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          if (isUrgent) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.powerZone6.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: AppColors.powerZone6),
                                              ),
                                              child: const Text(
                                                'PILNE',
                                                style: TextStyle(
                                                  color: AppColors.powerZone6,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          Text(
                                            '${msg.date.year}-${msg.date.month.toString().padLeft(2, '0')}-${msg.date.day.toString().padLeft(2, '0')}',
                                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                                          ),
                                          const SizedBox(width: 6),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.textSecondary),
                                            tooltip: 'Usuń wiadomość',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onPressed: () => notifier.deleteInboxMessage(msg.id),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        msg.subject,
                                        style: TextStyle(
                                          color: msg.isRead ? AppColors.textPrimary : Colors.white,
                                          fontSize: 13,
                                          fontWeight: msg.isRead ? FontWeight.w600 : FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Nadawca: ${msg.senderName} (${msg.senderRole})',
                                        style: const TextStyle(color: AppColors.goldAccent, fontSize: 11),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        msg.body,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (!msg.isRead) ...[
                                        const SizedBox(height: 8),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: () => notifier.markMessageAsRead(msg.id),
                                            icon: const Icon(Icons.check, size: 12),
                                            label: const Text('Oznacz jako przeczytaną'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppColors.cyanAccent,
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _parseHexColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.primaryAccent;
    }
  }
}

