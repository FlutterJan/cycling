import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../services/career/social_media_and_cycling_news_service.dart';
import '../../state/career_controller.dart';
import '../../state/career_state_notifier.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/cycling_news_feed_widget.dart';
import '../widgets/elevation_profile_chart.dart';
import '../widgets/power_curve_chart_widget.dart';
import '../widgets/rider_avatar_painter.dart';
import 'race_simulation_screen.dart';
import 'settings_and_mod_screen.dart';

/// Ekran główny biura menedżera (HQ Dashboard) w modułowym układzie Bento Grid:
/// 1. Karta najbliższego wyścigu z interaktywnym mini-profilem wysokościowym trasy.
/// 2. Skrzynka odbiorcza dyrektora sportowego (maile od sponsorów, agentów, lekarza i mechaników).
/// 3. Podsumowanie formy kluczowych liderów zespołu (CTL/ATL, wskaźnik świeżości, zdrowie).
/// 4. Wykres finansów i pas startowy klubu (prognoza przepływu gotówki na cały sezon).
/// 5. Szybki podgląd rankingu drużynowego UCI WorldTour z pozycją drużyny gracza.
class DashboardHqScreen extends ConsumerStatefulWidget {
  const DashboardHqScreen({super.key});

  @override
  ConsumerState<DashboardHqScreen> createState() => _DashboardHqScreenState();
}

class _DashboardHqScreenState extends ConsumerState<DashboardHqScreen> {
  // Wybrana wiadomość do podglądu w dialogu
  CareerInboxMessage? _selectedMessage;

  @override
  Widget build(BuildContext context) {
    final careerUiState = ref.watch(careerProvider);
    final careerController = ref.read(careerProvider.notifier);
    final careerState = ref.watch(careerStateNotifierProvider);
    final careerStateNotifier = ref.read(careerStateNotifierProvider.notifier);
    final simController = ref.read(raceSimulationProvider.notifier);

    final save = careerUiState.save;

    if (save == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.goldAccent),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 1050;
        final bool isTablet = constraints.maxWidth >= 720 && constraints.maxWidth < 1050;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Górny nagłówek biura menedżera (HQ Greeting & Overview Bar)
              _buildManagerHqHeader(save),
              const SizedBox(height: 16),

              // 2. Modułowy układ Bento Grid
              if (isDesktop)
                _buildDesktopBentoGrid(
                  context: context,
                  save: save,
                  careerState: careerState,
                  careerStateNotifier: careerStateNotifier,
                  careerController: careerController,
                  simController: simController,
                )
              else
                _buildStackedBentoGrid(
                  context: context,
                  save: save,
                  careerState: careerState,
                  careerStateNotifier: careerStateNotifier,
                  careerController: careerController,
                  simController: simController,
                  isTablet: isTablet,
                ),
            ],
          ),
        );
      },
    );
  }


  // ===========================================================================
  // 1. NAGŁÓWEK BIURA MENEDŻERA (HQ GREETING BAR)
  // ===========================================================================

  Widget _buildManagerHqHeader(CareerSave save) {
    final playerTeam = save.playerTeam;
    final teamColor = _parseHexColor(playerTeam.primaryJerseyColorHex);

    // Obliczenie postępu sezonu (np. dzień X / 365)
    final startOfYear = DateTime(save.currentSeasonYear, 1, 1);
    final dayOfYear = save.currentDate.difference(startOfYear).inDays + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo / Herb drużyny gracza
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: teamColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: teamColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.directions_bike_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 14),

          // Tytuł i nazwa menedżera
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'BIURO DYREKTORA SPORTOWEGO',
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        playerTeam.division.name.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.cyanAccent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${playerTeam.name} • ${save.playerManagerName}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          // Pigułka z dniem sezonu
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timeline_rounded, size: 14, color: AppColors.goldAccent),
                const SizedBox(width: 6),
                Text(
                  'Dzień $dayOfYear/365 • Sezon ${save.currentSeasonYear}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
        ],
      ),
    );
  }


  // ===========================================================================
  // 2. UKŁAD BENTO GRID (DESKTOP: 3 RZĘDY MODUŁOWE)
  // ===========================================================================

  Widget _buildDesktopBentoGrid({
    required BuildContext context,
    required CareerSave save,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
    required CareerController careerController,
    required RaceSimulationNotifier simController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // RZĄD 1: Karta wyścigu (7 cols) + Skrzynka odbiorcza (5 cols)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _buildNearestRaceHeroCard(context, save, simController),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: _buildInboxHqCard(context, save, careerState, careerStateNotifier),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // RZĄD 2: Podsumowanie formy liderów (6 cols) + Wykres finansów (6 cols)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _buildLeadersReadinessCard(context, save),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: _buildFinancialRunwayCard(context, save),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // RZĄD 3: Szybki podgląd rankingu UCI WorldTour (12 cols)
        _buildUciRankingLeaderboardCard(context, save),
        const SizedBox(height: 16),

        // RZĄD 4: Strumień Mediów Kolarskich & Peloton Social (12 cols)
        _buildCyclingNewsSection(save, careerState, careerStateNotifier),
      ],
    );
  }


  // ===========================================================================
  // 3. UKŁAD BENTO GRID DLA TABLETÓW I TELEFONÓW (STACKED)
  // ===========================================================================

  Widget _buildStackedBentoGrid({
    required BuildContext context,
    required CareerSave save,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
    required CareerController careerController,
    required RaceSimulationNotifier simController,
    required bool isTablet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNearestRaceHeroCard(context, save, simController),
        const SizedBox(height: 16),
        _buildInboxHqCard(context, save, careerState, careerStateNotifier),
        const SizedBox(height: 16),
        _buildLeadersReadinessCard(context, save),
        const SizedBox(height: 16),
        _buildFinancialRunwayCard(context, save),
        const SizedBox(height: 16),
        _buildUciRankingLeaderboardCard(context, save),
        const SizedBox(height: 16),
        _buildCyclingNewsSection(save, careerState, careerStateNotifier),
      ],
    );
  }

  Widget _buildCyclingNewsSection(
    CareerSave save,
    CareerState careerState,
    CareerStateNotifier careerStateNotifier,
  ) {
    final items = careerState.newsFeed.isNotEmpty
        ? careerState.newsFeed
        : const SocialMediaAndCyclingNewsService().generateInitialFeed(save);

    return CyclingNewsFeedWidget(
      items: items,
      onToggleLike: careerState.newsFeed.isNotEmpty
          ? careerStateNotifier.toggleNewsLike
          : null,
      onToggleBookmark: careerState.newsFeed.isNotEmpty
          ? careerStateNotifier.toggleNewsBookmark
          : null,
      onRefresh: careerStateNotifier.refreshDailyNewsFeed,
    );
  }


  // ===========================================================================
  // 4. BENTO MODUŁ 1: NAJBLIŻSZY WYŚCIG Z MINI-PROFILEM TRASY
  // ===========================================================================

  Widget _buildNearestRaceHeroCard(
    BuildContext context,
    CareerSave save,
    RaceSimulationNotifier simController,
  ) {
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final nextRace = save.calendar.nextUpcomingRace;

    // Czy dzisiaj odbywa się etap wyścigu z udziałem gracza
    final bool isLiveToday = activeRace != null && activeStage != null;
    final TourRace? displayRace = isLiveToday ? activeRace : nextRace;
    final RaceStage? displayStage = isLiveToday
        ? activeStage
        : (nextRace != null && nextRace.stages.isNotEmpty ? nextRace.stages.first : null);

    if (displayRace == null || displayStage == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _bentoCardDecoration(),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_rounded, size: 40, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text(
                'Brak zaplanowanych wyścigów w najbliższym czasie.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final bool isPlayerInRace = displayRace.participatingTeamIds.contains(save.playerTeamId);
    final int elevationGain = displayStage.elevationGainMeters;
    final double distanceKm = displayStage.distanceKm;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _bentoCardDecoration(
        borderColor: isLiveToday ? AppColors.goldAccent.withValues(alpha: 0.7) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek karty z oznaczeniem statusu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLiveToday ? const Color(0xFF381E05) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLiveToday ? AppColors.goldAccent : Colors.white12,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiveToday ? Icons.local_fire_department_rounded : Icons.calendar_today_rounded,
                          size: 13,
                          color: isLiveToday ? AppColors.goldAccent : AppColors.cyanAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isLiveToday ? 'DZISIEJSZY ETAP' : 'NAJBLIŻSZY START',
                          style: TextStyle(
                            color: isLiveToday ? AppColors.goldAccent : AppColors.textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      displayRace.uciCategory.name.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.cyanAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${displayRace.countryIso} • Pula: €${_formatCompact(displayRace.prizePoolEur)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tytuł wyścigu i etapu
          Text(
            displayRace.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Etap ${displayStage.stageNumber}: ${displayStage.name} • ${_getStageTypeName(displayStage.stageType)}',
            style: const TextStyle(
              color: AppColors.goldAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Telemetria etapu (Dystans, Przewyższenie, Temperatura, Wiatr)
          Row(
            children: [
              _buildMiniMetric('Dystans', '${distanceKm.round()} km', Icons.straighten_rounded),
              const SizedBox(width: 10),
              _buildMiniMetric('Wznios', '+$elevationGain m', Icons.landscape_rounded),
              const SizedBox(width: 10),
              _buildMiniMetric('Pogoda', '${displayStage.baseTemperatureCelsius.round()}°C', Icons.wb_sunny_outlined),
              const SizedBox(width: 10),
              _buildMiniMetric('Wiatr', '${displayStage.windSpeedKmh.round()} km/h', Icons.air_rounded),
            ],
          ),
          const SizedBox(height: 14),

          // Mini-profil wysokościowy trasy (ElevationProfileChart)
          Container(
            height: 135,
            decoration: BoxDecoration(
              color: const Color(0xFF10131A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white10),
            ),
            clipBehavior: Clip.antiAlias,
            child: ElevationProfileChart(
              stage: displayStage,
              showHeader: false,
              enableScrubber: true,
            ),
          ),
          const SizedBox(height: 14),

          // Przycisk akcji
          if (isLiveToday && isPlayerInRace)
            ElevatedButton.icon(
              onPressed: () {
                _startRaceSimulation(context, save, displayStage, simController);
              },
              icon: const Icon(Icons.sports_score_rounded, size: 18),
              label: const Text('Przejdź do Odprawy i Rozpocznij Etap 🏁'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Wyścig ${displayRace.name} rozpocznie się ${displayRace.startDay} ${_getMonthName(displayRace.startMonth)}.'),
                    backgroundColor: AppColors.surfaceLight,
                  ),
                );
              },
              icon: const Icon(Icons.assignment_outlined, size: 16),
              label: Text(
                isPlayerInRace ? 'Zobacz Pełny Harmonogram i Skład' : 'Brak udziału w wyścigu',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 11),
                side: const BorderSide(color: Colors.white12),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildMiniMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ===========================================================================
  // 5. BENTO MODUŁ 2: SKRZYNKA ODBIORCZA (INBOX HQ)
  // ===========================================================================

  Widget _buildInboxHqCard(
    BuildContext context,
    CareerSave save,
    CareerState careerState,
    CareerStateNotifier careerStateNotifier,
  ) {
    final rawMessages = careerState.inboxMessages;

    // Jeśli skrzynka jest pusta, wygenerujmy realistyczne wiadomości operacyjne HQ
    final messages = rawMessages.isNotEmpty
        ? rawMessages.take(4).toList()
        : _generateDefaultHqMessages(save);

    final unreadCount = careerState.unreadMessagesCount;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek skrzynki
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.mark_email_unread_rounded, size: 18, color: AppColors.goldAccent),
                  const SizedBox(width: 8),
                  const Text(
                    'Skrzynka Odbiorcza HQ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.powerZone6,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => careerStateNotifier.markAllMessagesAsRead(),
                child: const Text(
                  'Przeczytane',
                  style: TextStyle(color: AppColors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Lista 4 kluczowych wiadomości (Sponsor, Agent, Lekarz, Mechanik)
          Column(
            children: [
              for (int idx = 0; idx < messages.length; idx++) ...[
                if (idx > 0) const SizedBox(height: 6),
                _buildInboxHqRow(context, messages[idx], careerStateNotifier),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInboxHqRow(
    BuildContext context,
    CareerInboxMessage msg,
    CareerStateNotifier careerStateNotifier,
  ) {
    final categoryColor = _getInboxCategoryColor(msg.category);
    final categoryIcon = _getInboxCategoryIcon(msg.category);

    return InkWell(
      onTap: () {
        _showMessageDialog(context, msg, careerStateNotifier);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: msg.isRead ? AppColors.surfaceLight.withValues(alpha: 0.4) : const Color(0xFF1E2433),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: msg.isRead ? Colors.transparent : categoryColor.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(categoryIcon, size: 14, color: categoryColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        msg.senderRole,
                        style: TextStyle(
                          color: categoryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        _formatShortDate(msg.date),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    msg.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: msg.isRead ? AppColors.textPrimary : Colors.white,
                      fontSize: 11.5,
                      fontWeight: msg.isRead ? FontWeight.w600 : FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  // ===========================================================================
  // 6. BENTO MODUŁ 3: PODSUMOWANIE FORMY LIDERÓW ZESPOŁU
  // ===========================================================================

  Widget _buildLeadersReadinessCard(BuildContext context, CareerSave save) {
    final playerTeam = save.playerTeam;
    final roster = save.playerRoster;

    // Wyłonienie 3 najważniejszych liderów drużyny
    final leaders = roster.where((r) =>
        r.contract.role == RiderRole.teamLeader ||
        r.contract.role == RiderRole.coLeader ||
        r.contract.role == RiderRole.sprinter ||
        r.potential >= 82).take(3).toList();

    // Jeśli brak zdefiniowanych ról, weźmy 3 najlepszych kolarzy wg FTP
    final displayLeaders = leaders.isNotEmpty
        ? leaders
        : (List<Rider>.from(roster)..sort((a, b) => b.physiology.ftpWatts.compareTo(a.physiology.ftpWatts))).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.military_tech_rounded, size: 18, color: AppColors.goldAccent),
                  SizedBox(width: 8),
                  Text(
                    'Forma Kluczowych Liderów',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Text(
                '${displayLeaders.length} Liderów GC/Sprint',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Karty liderów
          Column(
            children: [
              for (int idx = 0; idx < displayLeaders.length; idx++) ...[
                if (idx > 0) const SizedBox(height: 8),
                _buildLeaderRow(context, save, playerTeam, displayLeaders[idx]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderRow(
    BuildContext context,
    CareerSave save,
    CyclingTeam playerTeam,
    Rider rider,
  ) {
    final bool isInjured = rider.health.currentInjury != null;
    final double form = rider.physiology.form.clamp(0.0, 100.0);
    final double fatigue = rider.physiology.fatigue.clamp(0.0, 100.0);

    // Wskaźnik świeżości (TSB / Training Stress Balance)
    final double tsb = form - fatigue;
    final Color statusColor = tsb >= 10
        ? AppColors.powerZone3
        : (tsb >= -5 ? AppColors.goldAccent : AppColors.powerZone6);
    final String statusText = tsb >= 10
        ? 'Szczyt formy'
        : (tsb >= -5 ? 'Dobra dyspozycja' : 'Zmęczenie');

    final double wKg = rider.physiology.weightKg > 0
        ? rider.physiology.ftpWatts / rider.physiology.weightKg
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          // Wektorowy awatar kolarza
          RiderAvatarWidget(
            appearance: rider.appearance,
            team: playerTeam,
            size: 46,
          ),
          const SizedBox(width: 12),

          // Imię, rola i statystyki
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      rider.lastName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        rider.specialization.name.toUpperCase(),
                        style: const TextStyle(color: AppColors.goldAccent, fontSize: 8, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${rider.physiology.ftpWatts}W (${wKg.toStringAsFixed(1)} W/kg) • ${rider.age} lat',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                ),
                const SizedBox(height: 5),

                // Pasek formy (zielony) vs zmęczenia (czerwony)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Row(
                    children: [
                      Expanded(
                        flex: form.round(),
                        child: Container(height: 4, color: AppColors.powerZone3),
                      ),
                      Expanded(
                        flex: (100 - form).round().clamp(1, 100),
                        child: Container(height: 4, color: Colors.white10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Status gotowości / Zdrowie
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  isInjured ? 'KONTUZJA' : statusText,
                  style: TextStyle(
                    color: isInjured ? AppColors.powerZone6 : statusColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () => _showRiderPowerAnalysisDialog(context, save, rider),
                child: const Row(
                  children: [
                    Icon(Icons.show_chart_rounded, size: 13, color: AppColors.cyanAccent),
                    SizedBox(width: 2),
                    Text(
                      'PDC',
                      style: TextStyle(color: AppColors.cyanAccent, fontSize: 10, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // 7. BENTO MODUŁ 4: WYKRES FINANSÓW I PAS STARTOWY (RUNWAY CHART)
  // ===========================================================================

  Widget _buildFinancialRunwayCard(BuildContext context, CareerSave save) {
    final playerTeam = save.playerTeam;
    final spots = _generateCashCurve(save);

    final double runwayMonths = playerTeam.monthlyBurnRateEur > 0
        ? playerTeam.cashBalanceEur / playerTeam.monthlyBurnRateEur
        : 99.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_graph_rounded, size: 18, color: AppColors.powerZone3),
                  SizedBox(width: 8),
                  Text(
                    'Kondycja Finansowa i Budżet',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.powerZone3.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.powerZone3.withValues(alpha: 0.4)),
                ),
                child: Text(
                  'Pas startowy: ${runwayMonths.toStringAsFixed(1)} mies.',
                  style: const TextStyle(
                    color: AppColors.powerZone3,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Wskaźniki przychodów i wydatków
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo: €${(playerTeam.cashBalanceEur / 1000000).toStringAsFixed(2)} mln',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                'Wydatki: €${(playerTeam.monthlyBurnRateEur / 1000).round()}k/mies. • Sponsorzy: €${(playerTeam.monthlySponsorIncomeEur / 1000).round()}k/mies.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Wykres liniowy fl_chart (12 miesięcy sezonu)
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF161A24),
                    tooltipBorder: const BorderSide(color: Color(0xFF2E3447)),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Miesiąc ${spot.x.round()}: €${spot.y.toStringAsFixed(2)} mln',
                          const TextStyle(
                            color: AppColors.powerZone3,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1.0,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 1.0,
                      getTitlesWidget: (val, _) => Text(
                        '€${val.toStringAsFixed(1)}M',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (val, _) {
                        const mNames = ['Sty', 'Mar', 'Maj', 'Lip', 'Sie', 'Lis'];
                        final idx = ((val - 1) / 2).floor().clamp(0, mNames.length - 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            mNames[idx],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.powerZone3,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.powerZone3.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  List<FlSpot> _generateCashCurve(CareerSave save) {
    final curMonth = save.currentDate.month;
    final curCash = save.playerTeam.cashBalanceEur / 1000000.0;
    final netMonthly = save.playerTeam.netMonthlyCashflowEur / 1000000.0;

    final spots = <FlSpot>[];
    for (int m = 1; m <= 12; m++) {
      final diff = m - curMonth;
      final val = (curCash + (diff * netMonthly)).clamp(0.2, 50.0);
      spots.add(FlSpot(m.toDouble(), val));
    }
    return spots;
  }

  // ===========================================================================
  // 8. BENTO MODUŁ 5: SZYBKI PODGLĄD RANKINGU UCI WORLDTOUR
  // ===========================================================================

  Widget _buildUciRankingLeaderboardCard(BuildContext context, CareerSave save) {
    final allTeams = List<CyclingTeam>.from(save.teams)
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));

    // Jeśli baza ma mało drużyn, dodajmy aktualną
    if (!allTeams.any((t) => t.id == save.playerTeamId)) {
      allTeams.add(save.playerTeam);
      allTeams.sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));
    }

    final int playerRank = allTeams.indexWhere((t) => t.id == save.playerTeamId) + 1;
    final int topRankPoints = allTeams.isNotEmpty ? allTeams.first.uciPointsSeason : 1;
    final int playerPoints = save.playerTeam.uciPointsSeason;

    // Weźmy Top 4 drużyny
    final top4 = allTeams.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _bentoCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.leaderboard_rounded, size: 18, color: AppColors.cyanAccent),
                  const SizedBox(width: 8),
                  const Text(
                    'Ranking Drużynowy UCI WorldTour 2026',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Twoje miejsce: #$playerRank',
                      style: const TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Łącznie: $playerPoints pkt UCI',
                style: const TextStyle(color: AppColors.cyanAccent, fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Pasek liderów i drużyny gracza
          Row(
            children: [
              ...List.generate(top4.length, (idx) {
                final team = top4[idx];
                final isPlayer = team.id == save.playerTeamId;
                final rank = idx + 1;

                Color medalColor;
                if (rank == 1) {
                  medalColor = const Color(0xFFFFD700);
                } else if (rank == 2) {
                  medalColor = const Color(0xFFC0C0C0);
                } else if (rank == 3) {
                  medalColor = const Color(0xFFCD7F32);
                } else {
                  medalColor = AppColors.cyanAccent;
                }

                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: idx < top4.length - 1 ? 10 : 0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isPlayer ? const Color(0xFF1E2838) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isPlayer ? AppColors.goldAccent : Colors.white10,
                        width: isPlayer ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '#$rank',
                              style: TextStyle(
                                color: medalColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${team.uciPointsSeason} pkt',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          team.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isPlayer ? AppColors.goldAccent : AppColors.textPrimary,
                            fontWeight: isPlayer ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }


  // ===========================================================================
  // 9. METODY POMOCNICZE I DIALOGI
  // ===========================================================================

  BoxDecoration _bentoCardDecoration({Color? borderColor}) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor ?? AppTheme.borderColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }


  void _showMessageDialog(
    BuildContext context,
    CareerInboxMessage msg,
    CareerStateNotifier notifier,
  ) {
    notifier.markMessageAsRead(msg.id);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Row(
            children: [
              Icon(
                _getInboxCategoryIcon(msg.category),
                color: _getInboxCategoryColor(msg.category),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  msg.subject,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Od: ${msg.senderName} (${msg.senderRole})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.goldAccent),
                    ),
                    Text(
                      _formatShortDate(msg.date),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Text(
                  msg.body,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Zamknij'),
            ),
          ],
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


  void _startRaceSimulation(
    BuildContext context,
    CareerSave save,
    RaceStage activeStage,
    RaceSimulationNotifier simController,
  ) {
    final Map<String, Rider> allRidersMap = {
      for (final r in save.riders) r.id: r,
    };
    final Map<String, CyclingTeam> allTeamsMap = {
      for (final t in save.teams) t.id: t,
    };

    final Map<String, CompleteBike> allBikesMap = {};
    for (final r in save.riders) {
      final team = allTeamsMap[r.contract.teamId];
      final bike = (team?.teamBikes.isNotEmpty ?? false) ? team!.teamBikes.first : null;
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


  List<CareerInboxMessage> _generateDefaultHqMessages(CareerSave save) {
    final now = save.currentDate;
    return [
      CareerInboxMessage(
        id: 'hq_msg_sponsor',
        date: now.subtract(const Duration(hours: 4)),
        senderName: 'Aethel Watches',
        senderRole: 'Główny Sponsor',
        subject: 'Zadowolenie z wyników w klasykach • Cel: Top 5 GC',
        body: 'Zarząd z uznaniem obserwuje postawę zespołu. Przypominamy, że premia €150k zostanie uruchomiona po ukończeniu Tour de France w pierwszej piątce.',
        category: InboxCategory.sponsorNews,
        priority: InboxPriority.urgent,
        isRead: false,
      ),
      CareerInboxMessage(
        id: 'hq_msg_agent',
        date: now.subtract(const Duration(hours: 14)),
        senderName: 'Jean-Paul Ricard',
        senderRole: 'Agent Lidera Zespołu',
        subject: 'Klauzula przedłużenia kontraktu na kolejne 2 lata',
        body: 'Mój klient czuje się doskonale w drużynie. Jesteśmy gotowi podpisać umowę na sezony 2027-2028 przy zachowaniu roli głównego lidera na Grand Toury.',
        category: InboxCategory.transferMarket,
        priority: InboxPriority.normal,
        isRead: false,
      ),
      CareerInboxMessage(
        id: 'hq_msg_doctor',
        date: now.subtract(const Duration(days: 1)),
        senderName: 'Dr. Marco Vandi',
        senderRole: 'Lekarz Zespołowy',
        subject: 'Raport regeneracji: wskaźniki HRV i kinazy w normie',
        body: 'Wszyscy kluczowi liderzy pomyślnie zakończyli cykl zabiegów regeneracyjnych. Brak stanów zapalnych, gotowość do najbliższego etapu wynosi 100%.',
        category: InboxCategory.medicalReport,
        priority: InboxPriority.normal,
        isRead: true,
      ),
      CareerInboxMessage(
        id: 'hq_msg_mechanic',
        date: now.subtract(const Duration(days: 2)),
        senderName: 'Laurent Mercier',
        senderRole: 'Główny Mechanik',
        subject: 'Przygotowanie stożków 65mm i woskowanie napędów',
        body: 'Zakończyliśmy inspekcję łańcuchów w kąpieli woskowej oraz przygotowaliśmy koła aero 65mm dla pociągu sprinterskiego.',
        category: InboxCategory.general,
        priority: InboxPriority.low,
        isRead: true,
      ),
    ];
  }

  Color _getInboxCategoryColor(InboxCategory category) {
    switch (category) {
      case InboxCategory.sponsorNews:
        return AppColors.goldAccent;
      case InboxCategory.transferMarket:
        return AppColors.cyanAccent;
      case InboxCategory.medicalReport:
        return AppColors.powerZone6;
      case InboxCategory.raceBriefing:
      case InboxCategory.raceResults:
        return AppColors.powerZone3;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getInboxCategoryIcon(InboxCategory category) {
    switch (category) {
      case InboxCategory.sponsorNews:
        return Icons.monetization_on_rounded;
      case InboxCategory.transferMarket:
        return Icons.handshake_rounded;
      case InboxCategory.medicalReport:
        return Icons.medical_services_rounded;
      case InboxCategory.raceBriefing:
        return Icons.flag_rounded;
      case InboxCategory.raceResults:
        return Icons.emoji_events_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  String _getStageTypeName(StageType type) {
    switch (type) {
      case StageType.flat:
        return 'Etap Płaski (Dla Sprinterów)';
      case StageType.hilly:
        return 'Etap Pagórkowaty (Puncheur)';
      case StageType.highMountain:
        return 'Wysokogórski (Liderzy GC)';
      case StageType.summitFinish:
        return 'Finał na Podjeździe (MTF)';
      case StageType.individualTimeTrial:
        return 'Jazda Indywidualna na Czas (ITT)';
      case StageType.teamTimeTrial:
        return 'Jazda Drużynowa na Czas (TTT)';
      case StageType.cobbleClassic:
        return 'Sektory Brukowe (Klasyk)';
    }
  }

  Color _parseHexColor(String hexString, [Color fallback = AppColors.primaryAccent]) {
    try {
      String hex = hexString.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      if (hex.length == 8) return Color(int.parse(hex, radix: 16));
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  String _formatShortDate(DateTime dt) {
    const months = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru'];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _getMonthName(int month) {
    const months = ['stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca', 'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia'];
    return months[(month - 1).clamp(0, 11)];
  }

  String _formatCompact(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).round()}k';
    return '$amount';
  }
}

