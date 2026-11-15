import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../models/rider/rider_contract.dart';
import '../../models/team/cycling_team.dart';
import '../../models/team/sponsor_contract.dart';
import '../../services/career/ai_team_transfer_simulation_service.dart';
import '../../services/career/social_media_and_cycling_news_service.dart';
import '../../state/career_controller.dart';
import '../../state/career_state_notifier.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/custom_carbon_and_glass_containers.dart';
import '../widgets/cycling_news_feed_widget.dart';
import '../widgets/elevation_profile_chart.dart';
import '../widgets/power_curve_chart_widget.dart';
import '../widgets/pro_cycling_stats_table_widget.dart';
import '../widgets/rider_avatar_painter.dart';
import 'pre_race_briefing_screen.dart';
import 'race_simulation_screen.dart';
import 'settings_and_mod_screen.dart';

/// Ekran główny Centrum Dowodzenia (HQ Dashboard) w modułowym układzie Bento Grid:
/// 1. Pasek "Transfer Ticker" z najnowszymi wydarzeniami transferowymi ze świata gry.
/// 2. Interaktywny widżet Najbliższego Wyścigu (`CarbonFiberCard`) z profilem trasy,
///    składem drużyny i przyciskiem przejścia do odprawy przedstartowej.
/// 3. Kafelek Stanu Liderów (forma TSB, morale, dni do szczytu formy) + PDC.
/// 4. Kafelek Zadowolenia Sponsora Tytularnego z postępem 3 głównych celów sezonowych.
/// 5. Kafelek Szybkich Akcji (kontrakty, laboratorium, rekonesans, medycyna/poczta).
/// 6. Skrzynka odbiorcza HQ, Finanse, Ranking UCI oraz tabele `ProCyclingStatsTableWidget`
///    i strumień `CyclingNewsFeedWidget`.
class DashboardHqScreen extends ConsumerStatefulWidget {
  const DashboardHqScreen({super.key});

  @override
  ConsumerState<DashboardHqScreen> createState() => _DashboardHqScreenState();
}

class _DashboardHqScreenState extends ConsumerState<DashboardHqScreen> {
  Timer? _tickerTimer;
  int _tickerIndex = 0;
  bool _isTickerPaused = false;
  bool _showRaceStartlistPcs = false;

  @override
  void initState() {
    super.initState();
    _tickerTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || _isTickerPaused) return;
      setState(() {
        _tickerIndex++;
      });
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final careerUiState = ref.watch(careerProvider);
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
        final bool isTablet =
            constraints.maxWidth >= 720 && constraints.maxWidth < 1050;
        final bool isCompact = constraints.maxWidth < 520;
        final double horizontalPadding = isCompact ? 12 : 20;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Górny nagłówek biura menedżera (HQ Greeting & Overview Bar)
              _buildManagerHqHeader(save, isCompact),
              const SizedBox(height: 12),

              // 2. Pasek "Transfer Ticker" na żywo
              _buildTransferTickerBar(context, save, careerState, isCompact),
              const SizedBox(height: 16),

              // 3. Modułowy układ Bento Grid
              if (isDesktop)
                _buildDesktopBentoGrid(
                  context: context,
                  save: save,
                  careerState: careerState,
                  careerStateNotifier: careerStateNotifier,
                  simController: simController,
                )
              else
                _buildStackedBentoGrid(
                  context: context,
                  save: save,
                  careerState: careerState,
                  careerStateNotifier: careerStateNotifier,
                  simController: simController,
                  isTablet: isTablet,
                  isCompact: isCompact,
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

  Widget _buildManagerHqHeader(CareerSave save, bool isCompact) {
    final playerTeam = save.playerTeam;
    final teamColor = _parseHexColor(playerTeam.primaryJerseyColorHex);
    final startOfYear = DateTime(save.currentSeasonYear, 1, 1);
    final dayOfYear = save.currentDate.difference(startOfYear).inDays + 1;

    return CarbonFiberCard(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 18,
        vertical: 14,
      ),
      accentTone: CarbonAccentTone.gold,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                  child: Icon(
                    Icons.directions_bike_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        const Text(
                          'BIURO DYREKTORA SPORTOWEGO',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.goldAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Text(
                            playerTeam.division.name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timeline_rounded,
                      size: 14,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Dzień $dayOfYear/365 • Sezon ${save.currentSeasonYear}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              _HqIconButton(
                icon: Icons.settings_suggest_rounded,
                tooltip: 'Ustawienia 3D & Edytor Bazy (Mody)',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsAndModScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. PASEK "TRANSFER TICKER"
  // ===========================================================================

  Widget _buildTransferTickerBar(
    BuildContext context,
    CareerSave save,
    CareerState careerState,
    bool isCompact,
  ) {
    final List<TransferNewsItem> tickerItems =
        careerState.recentTransferNews.isNotEmpty
            ? careerState.recentTransferNews
            : _buildFallbackTransferNews(save);

    final int safeIndex =
        tickerItems.isEmpty ? 0 : _tickerIndex % tickerItems.length;
    final TransferNewsItem? currentItem =
        tickerItems.isEmpty ? null : tickerItems[safeIndex];

    return MouseRegion(
      onEnter: (_) => setState(() => _isTickerPaused = true),
      onExit: (_) => setState(() => _isTickerPaused = false),
      child: CarbonFiberCard(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 12 : 16,
          vertical: 10,
        ),
        accentTone: CarbonAccentTone.burgundy,
        onTap: currentItem != null
            ? () => _showTransferDetailDialog(context, currentItem)
            : null,
        semanticLabel: 'Transfer Ticker z najnowszymi informacjami rynkowymi',
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.swap_horiz_rounded,
                    size: 13,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isCompact ? 'TRANSFERY' : 'TRANSFER TICKER',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.goldAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  currentItem?.tickerHeadline ??
                      'Rynek transferowy UCI pozostaje otwarty — brak nowych ruchów.',
                  key: ValueKey<String>(currentItem?.id ?? 'empty_ticker'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (tickerItems.length > 1) ...[
              const SizedBox(width: 8),
              if (!isCompact)
                Text(
                  '${safeIndex + 1}/${tickerItems.length}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              const SizedBox(width: 6),
              _HqIconButton(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Poprzedni transfer',
                size: 28,
                onPressed: () {
                  setState(() {
                    _tickerIndex = (_tickerIndex - 1) < 0
                        ? tickerItems.length - 1
                        : _tickerIndex - 1;
                  });
                },
              ),
              const SizedBox(width: 4),
              _HqIconButton(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Następny transfer',
                size: 28,
                onPressed: () {
                  setState(() {
                    _tickerIndex = (_tickerIndex + 1) % tickerItems.length;
                  });
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. UKŁAD BENTO GRID (DESKTOP & STACKED)
  // ===========================================================================

  Widget _buildDesktopBentoGrid({
    required BuildContext context,
    required CareerSave save,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
    required RaceSimulationNotifier simController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // RZĄD 1: Najbliższy Wyścig ze składem (7 cols) + Szybkie Akcje & Skrzynka HQ (5 cols)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: _buildNearestRaceHeroCard(
                context,
                save,
                simController,
                isCompact: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildQuickActionsCard(context, save, careerState),
                  const SizedBox(height: 16),
                  _buildInboxHqCard(
                    context,
                    save,
                    careerState,
                    careerStateNotifier,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // RZĄD 2: Stan Liderów (TSB, Morale, Szczyt Formy) (6 cols) + Sponsor Tytularny (6 cols)
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
              child: _buildTitleSponsorSatisfactionCard(context, save),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // RZĄD 3: Tabela PCS Kadry / Listy Startowej (#198)
        _buildProCyclingStatsRosterSection(context, save),
        const SizedBox(height: 16),

        // RZĄD 4: Wykres Finansów (6 cols) + Ranking Drużynowy UCI (6 cols)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 6,
              child: _buildFinancialRunwayCard(context, save, isCompact: false),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 6,
              child: _buildUciRankingLeaderboardCard(
                context,
                save,
                isCompact: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // RZĄD 5: Strumień Mediów Kolarskich & Peloton Social (#197)
        _buildCyclingNewsSection(save, careerState, careerStateNotifier),
      ],
    );
  }

  Widget _buildStackedBentoGrid({
    required BuildContext context,
    required CareerSave save,
    required CareerState careerState,
    required CareerStateNotifier careerStateNotifier,
    required RaceSimulationNotifier simController,
    required bool isTablet,
    required bool isCompact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildNearestRaceHeroCard(
          context,
          save,
          simController,
          isCompact: isCompact,
        ),
        const SizedBox(height: 16),
        _buildQuickActionsCard(context, save, careerState),
        const SizedBox(height: 16),
        if (isTablet)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLeadersReadinessCard(context, save)),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTitleSponsorSatisfactionCard(context, save),
              ),
            ],
          )
        else ...[
          _buildLeadersReadinessCard(context, save),
          const SizedBox(height: 16),
          _buildTitleSponsorSatisfactionCard(context, save),
        ],
        const SizedBox(height: 16),
        _buildInboxHqCard(context, save, careerState, careerStateNotifier),
        const SizedBox(height: 16),
        _buildProCyclingStatsRosterSection(context, save),
        const SizedBox(height: 16),
        _buildFinancialRunwayCard(context, save, isCompact: isCompact),
        const SizedBox(height: 16),
        _buildUciRankingLeaderboardCard(context, save, isCompact: isCompact),
        const SizedBox(height: 16),
        _buildCyclingNewsSection(save, careerState, careerStateNotifier),
      ],
    );
  }

  // ===========================================================================
  // 4. BENTO MODUŁ 1: INTERAKTYWNY WIDŻET NAJBLIŻSZEGO WYŚCIGU
  // ===========================================================================

  Widget _buildNearestRaceHeroCard(
    BuildContext context,
    CareerSave save,
    RaceSimulationNotifier simController, {
    required bool isCompact,
  }) {
    final activeRace = save.calendar.activeRace;
    final activeStage = save.calendar.activeStage;
    final nextRace = save.calendar.nextUpcomingRace;

    final bool isLiveToday = activeRace != null && activeStage != null;
    final TourRace? displayRace = isLiveToday ? activeRace : nextRace;
    final RaceStage? displayStage = isLiveToday
        ? activeStage
        : (nextRace != null && nextRace.stages.isNotEmpty
            ? nextRace.stages.first
            : null);

    if (displayRace == null || displayStage == null) {
      return const CarbonFiberCard(
        accentTone: CarbonAccentTone.burgundy,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
                SizedBox(height: 8),
                Text(
                  'Brak zaplanowanych wyścigów w najbliższym czasie.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isPlayerInRace =
        displayRace.participatingTeamIds.contains(save.playerTeamId);
    final int elevationGain = displayStage.elevationGainMeters;
    final double distanceKm = displayStage.distanceKm;
    final List<Rider> raceLineup = _resolveRaceLineup(save, displayRace);

    return CarbonFiberCard(
      accentTone:
          isLiveToday ? CarbonAccentTone.gold : CarbonAccentTone.burgundy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nagłówek karty z oznaczeniem statusu
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLiveToday
                          ? const Color(0xFF381E05)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isLiveToday
                            ? AppColors.goldAccent
                            : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLiveToday
                              ? Icons.local_fire_department_rounded
                              : Icons.calendar_today_rounded,
                          size: 13,
                          color: isLiveToday
                              ? AppColors.goldAccent
                              : AppColors.cyanAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isLiveToday ? 'DZISIEJSZY ETAP' : 'NAJBLIŻSZY START',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: isLiveToday
                                ? AppColors.goldAccent
                                : AppColors.textPrimary,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      displayRace.uciCategory.name.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
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
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tytuł wyścigu i etapu
          Text(
            displayRace.name,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Etap ${displayStage.stageNumber}: ${displayStage.name} • ${_getStageTypeName(displayStage.stageType)}',
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.goldAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Telemetria etapu (responsywna siatka na 390px)
          if (isCompact)
            Column(
              children: [
                Row(
                  children: [
                    _buildMiniMetric(
                      'Dystans',
                      '${distanceKm.round()} km',
                      Icons.straighten_rounded,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniMetric(
                      'Wznios',
                      '+$elevationGain m',
                      Icons.landscape_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildMiniMetric(
                      'Pogoda',
                      '${displayStage.baseTemperatureCelsius.round()}°C',
                      Icons.wb_sunny_outlined,
                    ),
                    const SizedBox(width: 8),
                    _buildMiniMetric(
                      'Wiatr',
                      '${displayStage.windSpeedKmh.round()} km/h',
                      Icons.air_rounded,
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              children: [
                _buildMiniMetric(
                  'Dystans',
                  '${distanceKm.round()} km',
                  Icons.straighten_rounded,
                ),
                const SizedBox(width: 10),
                _buildMiniMetric(
                  'Wznios',
                  '+$elevationGain m',
                  Icons.landscape_rounded,
                ),
                const SizedBox(width: 10),
                _buildMiniMetric(
                  'Pogoda',
                  '${displayStage.baseTemperatureCelsius.round()}°C',
                  Icons.wb_sunny_outlined,
                ),
                const SizedBox(width: 10),
                _buildMiniMetric(
                  'Wiatr',
                  '${displayStage.windSpeedKmh.round()} km/h',
                  Icons.air_rounded,
                ),
              ],
            ),
          const SizedBox(height: 14),

          // Interaktywny profil wysokościowy trasy
          Container(
            height: 138,
            decoration: BoxDecoration(
              color: const Color(0xFF10131A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: ElevationProfileChart(
              stage: displayStage,
              showHeader: false,
              enableScrubber: true,
            ),
          ),
          const SizedBox(height: 14),

          // Sekcja składu na wyścig + przełącznik podglądu PCS
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                'SKŁAD NA WYŚCIG (${raceLineup.length})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              _InteractiveTextToggle(
                label: _showRaceStartlistPcs
                    ? 'Widok kafelków'
                    : 'Tabela PCS składu',
                icon: _showRaceStartlistPcs
                    ? Icons.grid_view_rounded
                    : Icons.table_rows_rounded,
                onTap: () {
                  setState(() {
                    _showRaceStartlistPcs = !_showRaceStartlistPcs;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            child: _showRaceStartlistPcs
                ? ProCyclingStatsTableWidget(
                    key: const ValueKey<String>('race_lineup_pcs'),
                    rows: _mapRidersToPcsRows(
                      raceLineup,
                      save.playerTeam,
                    ),
                    mode: PcsTableMode.startlist,
                    showSearchBar: false,
                    showSpecializationFilters: false,
                    showPlayerTeamToggle: false,
                    maxTableHeight: 210,
                    padding: EdgeInsets.zero,
                    onRiderTap: (row) {
                      final rider = raceLineup
                          .where((r) => r.id == row.id)
                          .firstOrNull;
                      if (rider != null) {
                        _showRiderPowerAnalysisDialog(context, save, rider);
                      }
                    },
                  )
                : Wrap(
                    key: const ValueKey<String>('race_lineup_chips'),
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final rider in raceLineup)
                        _LineupRiderChip(
                          rider: rider,
                          team: save.playerTeam,
                          onTap: () => _showRiderPowerAnalysisDialog(
                            context,
                            save,
                            rider,
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),

          // Przyciski akcji przejścia do odprawy / startu
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PrimaryCtaButton(
                label: isLiveToday && isPlayerInRace
                    ? 'Przejdź do Odprawy Przedstartowej'
                    : (isPlayerInRace
                        ? 'Otwórz Odprawę Taktyczną'
                        : 'Zgłoś Skład w Kalendarzu'),
                icon: isPlayerInRace
                    ? Icons.sports_score_rounded
                    : Icons.calendar_month_rounded,
                isGold: isLiveToday && isPlayerInRace,
                enabled: true,
                onPressed: () {
                  if (isPlayerInRace) {
                    _openPreRaceBriefing(context, displayRace, displayStage);
                  } else {
                    _navigateToRoute(
                      context,
                      AppRoutes.calendar,
                      'Otwórz zakładkę Kalendarza UCI, aby zgłosić drużynę.',
                    );
                  }
                },
              ),
              if (isLiveToday && isPlayerInRace)
                _SecondaryActionButton(
                  label: 'Szybki Start 3D',
                  icon: Icons.play_arrow_rounded,
                  onPressed: () {
                    _startRaceSimulation(
                      context,
                      save,
                      displayStage,
                      simController,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 9),
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
                Icon(icon, size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. KAFELEK SZYBKICH AKCJI (QUICK ACTIONS)
  // ===========================================================================

  Widget _buildQuickActionsCard(
    BuildContext context,
    CareerSave save,
    CareerState careerState,
  ) {
    final List<_QuickActionItem> actions =
        _buildDynamicQuickActions(context, save, careerState);

    return CarbonFiberCard(
      accentTone: CarbonAccentTone.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: AppColors.goldAccent,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Szybkie Akcje HQ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  '${actions.length} ZADAŃ',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _InteractiveQuickActionTile(item: actions[i]),
          ],
        ],
      ),
    );
  }

  List<_QuickActionItem> _buildDynamicQuickActions(
    BuildContext context,
    CareerSave save,
    CareerState careerState,
  ) {
    final int expiringContracts = save.playerRoster
        .where((r) => r.contract.isExpiring(save.currentSeasonYear))
        .length;
    final int injuredCount =
        save.playerRoster.where((r) => r.health.currentInjury != null).length;
    final TourRace? nextRace =
        save.calendar.activeRace ?? save.calendar.nextUpcomingRace;
    final RaceStage? nextStage = save.calendar.activeStage ??
        (nextRace != null && nextRace.stages.isNotEmpty
            ? nextRace.stages.first
            : null);

    final String contractLabel = expiringContracts > 0
        ? '$expiringContracts kolarzy czeka na przedłużenie kontraktu'
        : '2 kolarzy czeka na przegląd przedłużenia kontraktu';

    final String reconTargetName = nextRace?.name ?? 'Monumentem';
    final String reconLabel = nextRace != null
        ? 'Dostępny rekonesans przed $reconTargetName'
        : 'Dostępny rekonesans przed Monumentem';

    return [
      _QuickActionItem(
        title: contractLabel,
        subtitle: 'Kadra & Negocjacje kontraktowe',
        icon: Icons.edit_document,
        accentColor: AppColors.amberWarning,
        badgeText: expiringContracts > 0 ? 'PILNE' : 'KADRA',
        onTap: () => _navigateToRoute(
          context,
          AppRoutes.roster,
          'Przejdź do Kadry Zespołu, aby przedłużyć kontrakty.',
        ),
      ),
      _QuickActionItem(
        title: 'Wyniki testów z Laboratorium gotowe',
        subtitle: 'Krzywe mleczanowe LT1/LT2, VLaMax i VO2max',
        icon: Icons.biotech_rounded,
        accentColor: AppColors.cyanAccent,
        badgeText: 'LAB',
        onTap: () => _navigateToRoute(
          context,
          AppRoutes.physiologyLab,
          'Przejdź do Laboratorium Wydolnościowego.',
        ),
      ),
      _QuickActionItem(
        title: reconLabel,
        subtitle: nextStage != null
            ? '${nextStage.name} • ${nextStage.distanceKm.round()} km'
            : 'Analiza sektorów i dobór ciśnienia opon',
        icon: Icons.map_rounded,
        accentColor: AppColors.statusSuccess,
        badgeText: 'RECON',
        onTap: () {
          if (nextRace != null && nextStage != null) {
            _openPreRaceBriefing(context, nextRace, nextStage);
          } else {
            _navigateToRoute(
              context,
              AppRoutes.calendar,
              'Przejdź do Kalendarza UCI.',
            );
          }
        },
      ),
      if (injuredCount > 0 || careerState.unreadMessagesCount > 0)
        _QuickActionItem(
          title: injuredCount > 0
              ? '$injuredCount zawodników wymaga opieki medycznej'
              : '${careerState.unreadMessagesCount} nieprzeczytanych raportów HQ',
          subtitle: injuredCount > 0
              ? 'Centrum Medyczne i protokoły regeneracji'
              : 'Skrzynka Odbiorcza Dyrektora Sportowego',
          icon: injuredCount > 0
              ? Icons.medical_services_rounded
              : Icons.mark_email_unread_rounded,
          accentColor: AppColors.crimsonAlert,
          badgeText: injuredCount > 0 ? 'MED' : 'INFO',
          onTap: () => _navigateToRoute(
            context,
            injuredCount > 0 ? AppRoutes.medical : AppRoutes.inbox,
            injuredCount > 0
                ? 'Otwórz Centrum Medyczne.'
                : 'Otwórz Skrzynkę Odbiorczą.',
          ),
        ),
    ];
  }

  // ===========================================================================
  // 6. KAFELEK STANU LIDERÓW (TSB, MORALE, DNI DO SZCZYTU FORMY)
  // ===========================================================================

  Widget _buildLeadersReadinessCard(BuildContext context, CareerSave save) {
    final playerTeam = save.playerTeam;
    final roster = save.playerRoster;

    final leaders = roster
        .where(
          (r) =>
              r.contract.role == RiderRole.teamLeader ||
              r.contract.role == RiderRole.coLeader ||
              r.contract.role == RiderRole.sprinter ||
              r.potential >= 82,
        )
        .take(3)
        .toList();

    final displayLeaders = leaders.isNotEmpty
        ? leaders
        : (List<Rider>.from(roster)
              ..sort((a, b) =>
                  b.physiology.ftpWatts.compareTo(a.physiology.ftpWatts)))
            .take(3)
            .toList();

    return CarbonFiberCard(
      accentTone: CarbonAccentTone.burgundy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.military_tech_rounded,
                      size: 18,
                      color: AppColors.goldAccent,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Stan Kluczowych Liderów',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${displayLeaders.length} Liderów',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (displayLeaders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Brak zakontraktowanych liderów w kadrze.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            )
          else
            Column(
              children: [
                for (int idx = 0; idx < displayLeaders.length; idx++) ...[
                  if (idx > 0) const SizedBox(height: 8),
                  _LeaderStatusRow(
                    rider: displayLeaders[idx],
                    team: playerTeam,
                    onOpenPdc: () => _showRiderPowerAnalysisDialog(
                      context,
                      save,
                      displayLeaders[idx],
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. KAFELEK ZADOWOLENIA SPONSORA TYTULARNEGO (3 CELE SEZONOWE)
  // ===========================================================================

  Widget _buildTitleSponsorSatisfactionCard(
    BuildContext context,
    CareerSave save,
  ) {
    final sponsors = save.playerTeam.sponsors;
    final SponsorContract? titleSponsor = sponsors
            .where((s) => s.sponsorTier == SponsorTier.titlePrimary)
            .firstOrNull ??
        sponsors.firstOrNull;

    if (titleSponsor == null) {
      return CarbonFiberCard(
        accentTone: CarbonAccentTone.gold,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sponsor Tytularny',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Brak aktywnego kontraktu ze sponsorem tytularnym.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _SecondaryActionButton(
              label: 'Przejdź do Sponsorów',
              icon: Icons.handshake_rounded,
              onPressed: () => _navigateToRoute(
                context,
                AppRoutes.sponsors,
                'Przejdź do zakładki Sponsorzy i Finanse.',
              ),
            ),
          ],
        ),
      );
    }

    final double satisfaction =
        titleSponsor.sponsorSatisfaction.clamp(0.0, 100.0);
    final Color satColor = satisfaction >= 75
        ? AppColors.statusSuccess
        : (satisfaction >= 45
            ? AppColors.amberWarning
            : AppColors.crimsonAlert);
    final String satStatus = satisfaction >= 80
        ? 'Zachwycony'
        : (satisfaction >= 60
            ? 'Zadowolony'
            : (satisfaction >= 40 ? 'Oczekuje wyników' : 'Zagrożony'));
    final List<SponsorObjective> topObjectives =
        titleSponsor.objectives.take(3).toList();

    return CarbonFiberCard(
      accentTone: CarbonAccentTone.gold,
      onTap: () => _navigateToRoute(
        context,
        AppRoutes.sponsors,
        'Otwarto panel Sponsora Tytularnego.',
      ),
      semanticLabel: 'Kafelek zadowolenia sponsora tytularnego',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleSponsor.companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Sponsor Tytularny • ${Formatters.formatCompactCurrency(titleSponsor.annualBudgetEur)}/rok',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 10.5,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: satColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: satColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '${satisfaction.round()}% • $satStatus',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: satColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Pasek zadowolenia sponsora
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: satisfaction / 100.0,
              minHeight: 6,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(satColor),
            ),
          ),
          const SizedBox(height: 14),

          const Text(
            '3 GŁÓWNE CELE SEZONOWE',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          if (topObjectives.isEmpty)
            const Text(
              'Brak aktywnych celów na ten sezon.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          else
            Column(
              children: [
                for (int i = 0; i < topObjectives.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _buildSponsorObjectiveRow(topObjectives[i]),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSponsorObjectiveRow(SponsorObjective objective) {
    final double pct = objective.progressPercentage;
    final Color barColor = objective.isCompleted
        ? AppColors.statusSuccess
        : (pct >= 50 ? AppColors.goldAccent : AppColors.accentBlue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: objective.isCompleted
              ? AppColors.statusSuccess.withValues(alpha: 0.45)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                objective.isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.track_changes_rounded,
                size: 14,
                color: barColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  objective.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '+${Formatters.formatCompactCurrency(objective.bonusPaymentEur)}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: (pct / 100.0).clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${pct.round()}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: barColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 8. TABELA PROCYCLINGSTATS KADRY (#198)
  // ===========================================================================

  Widget _buildProCyclingStatsRosterSection(
    BuildContext context,
    CareerSave save,
  ) {
    final rows = _mapRidersToPcsRows(save.playerRoster, save.playerTeam);

    return ProCyclingStatsTableWidget(
      rows: rows,
      mode: PcsTableMode.statistics,
      title: 'KADRA & STATYSTYKI PCS',
      subtitle: 'Aktualna forma TSB, moc progowa FTP i punkty UCI zawodników',
      showPlayerTeamToggle: false,
      secondaryMetricHeader: 'FTP',
      timeColumnHeader: 'TSB',
      pointsColumnHeader: 'UCI',
      maxTableHeight: 320,
      onRiderTap: (row) {
        final rider =
            save.playerRoster.where((r) => r.id == row.id).firstOrNull;
        if (rider != null) {
          _showRiderPowerAnalysisDialog(context, save, rider);
        }
      },
    );
  }

  // ===========================================================================
  // 9. SKRZYNKA ODBIORCZA HQ
  // ===========================================================================

  Widget _buildInboxHqCard(
    BuildContext context,
    CareerSave save,
    CareerState careerState,
    CareerStateNotifier careerStateNotifier,
  ) {
    final rawMessages = careerState.inboxMessages;
    final messages = rawMessages.isNotEmpty
        ? rawMessages.take(4).toList()
        : _generateDefaultHqMessages(save);
    final unreadCount = careerState.unreadMessagesCount;

    return CarbonFiberCard(
      accentTone: CarbonAccentTone.burgundy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 18,
                      color: AppColors.goldAccent,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Skrzynka Odbiorcza HQ',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.crimsonAlert,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _InteractiveTextToggle(
                label: 'Przeczytane',
                icon: Icons.done_all_rounded,
                onTap: () => careerStateNotifier.markAllMessagesAsRead(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (int idx = 0; idx < messages.length; idx++) ...[
            if (idx > 0) const SizedBox(height: 6),
            _buildInboxHqRow(context, messages[idx], careerStateNotifier),
          ],
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showMessageDialog(context, msg, careerStateNotifier),
        borderRadius: BorderRadius.circular(10),
        hoverColor: AppColors.surfaceLight.withValues(alpha: 0.7),
        focusColor: AppColors.goldAccent.withValues(alpha: 0.18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: msg.isRead
                ? AppColors.surfaceLight.withValues(alpha: 0.45)
                : const Color(0xFF1E2433),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: msg.isRead
                  ? AppTheme.borderColor.withValues(alpha: 0.6)
                  : categoryColor.withValues(alpha: 0.45),
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
                        Flexible(
                          child: Text(
                            msg.senderRole,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: categoryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatShortDate(msg.date),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textSecondary,
                            fontSize: 9.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color:
                            msg.isRead ? AppColors.textPrimary : Colors.white,
                        fontSize: 11.5,
                        fontWeight:
                            msg.isRead ? FontWeight.w600 : FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 10. FINANSE & RANKING UCI
  // ===========================================================================

  Widget _buildFinancialRunwayCard(
    BuildContext context,
    CareerSave save, {
    required bool isCompact,
  }) {
    final playerTeam = save.playerTeam;
    final spots = _generateCashCurve(save);
    final double runwayMonths = playerTeam.monthlyBurnRateEur > 0
        ? playerTeam.cashBalanceEur / playerTeam.monthlyBurnRateEur
        : 99.0;

    return CarbonFiberCard(
      accentTone: CarbonAccentTone.burgundy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_graph_rounded,
                    size: 18,
                    color: AppColors.statusSuccess,
                  ),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Kondycja Finansowa i Budżet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.statusSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.statusSuccess.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Pas startowy: ${runwayMonths.toStringAsFixed(1)} mies.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.statusSuccess,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                'Saldo: €${(playerTeam.cashBalanceEur / 1000000).toStringAsFixed(2)} mln',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'Wydatki: €${(playerTeam.monthlyBurnRateEur / 1000).round()}k/mies. • Sponsorzy: €${(playerTeam.monthlySponsorIncomeEur / 1000).round()}k/mies.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textSecondary,
                  fontSize: isCompact ? 10 : 10.5,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 175,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF161A24),
                    tooltipBorder: const BorderSide(color: AppTheme.borderColor),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          'Miesiąc ${spot.x.round()}: €${spot.y.toStringAsFixed(2)} mln',
                          const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.statusSuccess,
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
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: 1.0,
                      getTitlesWidget: (val, _) => Text(
                        '€${val.toStringAsFixed(1)}M',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 9.5,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      getTitlesWidget: (val, _) {
                        const mNames = [
                          'Sty',
                          'Mar',
                          'Maj',
                          'Lip',
                          'Sie',
                          'Lis',
                        ];
                        final idx =
                            ((val - 1) / 2).floor().clamp(0, mNames.length - 1);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            mNames[idx],
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
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
                    color: AppColors.statusSuccess,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.statusSuccess.withValues(alpha: 0.12),
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

  Widget _buildUciRankingLeaderboardCard(
    BuildContext context,
    CareerSave save, {
    required bool isCompact,
  }) {
    final allTeams = List<CyclingTeam>.from(save.teams)
      ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));

    if (!allTeams.any((t) => t.id == save.playerTeamId)) {
      allTeams.add(save.playerTeam);
      allTeams.sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));
    }

    final int playerRank =
        allTeams.indexWhere((t) => t.id == save.playerTeamId) + 1;
    final int playerPoints = save.playerTeam.uciPointsSeason;
    final top4 = allTeams.take(4).toList();

    return CarbonFiberCard(
      accentTone: CarbonAccentTone.gold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.leaderboard_rounded,
                    size: 18,
                    color: AppColors.cyanAccent,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Ranking UCI ${save.currentSeasonYear}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Text(
                      '#$playerRank',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.goldAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '$playerPoints pkt UCI',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isCompact)
            Column(
              children: [
                for (int idx = 0; idx < top4.length; idx++) ...[
                  if (idx > 0) const SizedBox(height: 8),
                  _buildUciTeamRankTile(
                    top4[idx],
                    rank: idx + 1,
                    isPlayer: top4[idx].id == save.playerTeamId,
                  ),
                ],
              ],
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    if (top4.isNotEmpty)
                      Expanded(
                        child: _buildUciTeamRankTile(
                          top4[0],
                          rank: 1,
                          isPlayer: top4[0].id == save.playerTeamId,
                        ),
                      ),
                    if (top4.length > 1) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildUciTeamRankTile(
                          top4[1],
                          rank: 2,
                          isPlayer: top4[1].id == save.playerTeamId,
                        ),
                      ),
                    ],
                  ],
                ),
                if (top4.length > 2) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildUciTeamRankTile(
                          top4[2],
                          rank: 3,
                          isPlayer: top4[2].id == save.playerTeamId,
                        ),
                      ),
                      if (top4.length > 3) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildUciTeamRankTile(
                            top4[3],
                            rank: 4,
                            isPlayer: top4[3].id == save.playerTeamId,
                          ),
                        ),
                      ] else
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUciTeamRankTile(
    CyclingTeam team, {
    required int rank,
    required bool isPlayer,
  }) {
    final Color medalColor = switch (rank) {
      1 => AppColors.goldAccent,
      2 => const Color(0xFFC0C0C0),
      3 => const Color(0xFFCD7F32),
      _ => AppColors.cyanAccent,
    };

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: isPlayer ? const Color(0xFF1E2838) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlayer ? AppColors.goldAccent : AppTheme.borderColor,
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
                  fontFamily: 'Inter',
                  color: medalColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                '${team.uciPointsSeason} pkt',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  fontFeatures: [FontFeature.tabularFigures()],
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
              fontFamily: 'Inter',
              color: isPlayer ? AppColors.goldAccent : AppColors.textPrimary,
              fontWeight: isPlayer ? FontWeight.w900 : FontWeight.w600,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 11. CYCLING NEWS (#197)
  // ===========================================================================

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
  // 12. METODY POMOCNICZE, NAWIGACJA I DIALOGI
  // ===========================================================================

  List<Rider> _resolveRaceLineup(CareerSave save, TourRace race) {
    final roster = List<Rider>.from(save.playerRoster);
    roster.sort((a, b) => b.potential.compareTo(a.potential));
    return roster.take(8).toList();
  }

  List<PcsRiderRowData> _mapRidersToPcsRows(
    List<Rider> riders,
    CyclingTeam team,
  ) {
    final Color primaryColor = _parseHexColor(team.primaryJerseyColorHex);
    final Color secondaryColor = _parseHexColor(team.secondaryJerseyColorHex);
    final String shortCode = team.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return List<PcsRiderRowData>.generate(riders.length, (idx) {
      final rider = riders[idx];
      final double tsb = rider.physiology.trainingStressBalanceTsb;
      final String tsbSign = tsb >= 0 ? '+' : '';
      return PcsRiderRowData(
        id: rider.id,
        rank: idx + 1,
        bibNumber: '${idx + 1}',
        firstName: rider.firstName,
        lastName: rider.lastName,
        nationalityIso: rider.nationalityIso,
        teamId: team.id,
        teamName: team.name,
        teamShortCode: shortCode.isNotEmpty ? shortCode : 'PRO',
        teamPrimaryColor: primaryColor,
        teamSecondaryColor: secondaryColor,
        age: rider.age,
        specialization: PcsSpecializationCategory.fromRiderSpecialization(
          rider.specialization,
        ),
        specializationLabel: rider.specialization.displayName,
        customTimeText: 'TSB $tsbSign${tsb.toStringAsFixed(0)}',
        points: rider.careerPointsUci,
        secondaryMetric: rider.physiology.ftpWatts,
        secondaryMetricText: '${rider.physiology.ftpWatts}W',
        isPlayerTeam: true,
        isLeader: rider.contract.role == RiderRole.teamLeader ||
            rider.contract.role == RiderRole.coLeader,
        isDisabled: rider.health.currentInjury != null,
      );
    });
  }

  List<TransferNewsItem> _buildFallbackTransferNews(CareerSave save) {
    final now = save.currentDate;
    final teams = save.teams;
    final String teamA =
        teams.isNotEmpty ? teams.first.name : save.playerTeam.name;
    final String teamB =
        teams.length > 1 ? teams[1].name : 'Alpecin-Deceuninck Pro';
    final String teamC =
        teams.length > 2 ? teams[2].name : 'Visma Lease-A-Bike';

    final riders = save.riders;
    final String rider1Name =
        riders.isNotEmpty ? riders.first.fullName : 'Kacper Majewski';
    final String rider2Name =
        riders.length > 1 ? riders[1].fullName : 'Julian Vermeulen';
    final String rider3Name =
        riders.length > 2 ? riders[2].fullName : 'Matteo Bellini';

    return [
      TransferNewsItem(
        id: 'ticker_fallback_1',
        date: now,
        riderId: riders.isNotEmpty ? riders.first.id : 'r_1',
        riderName: rider1Name,
        riderNationalityIso:
            riders.isNotEmpty ? riders.first.nationalityIso : 'POL',
        fromTeamId: null,
        fromTeamName: teamA,
        toTeamId: save.playerTeamId,
        toTeamName: teamB,
        contractAmountEur: 1450000,
        contractYears: 3,
        role: RiderRole.teamLeader,
        newsType: TransferNewsType.contractExtension,
        expertComment:
            'Kluczowy lider przedłużył umowę na 3 sezony po świetnych testach wydolnościowych.',
        isBreakingNews: true,
      ),
      TransferNewsItem(
        id: 'ticker_fallback_2',
        date: now.subtract(const Duration(hours: 8)),
        riderId: riders.length > 1 ? riders[1].id : 'r_2',
        riderName: rider2Name,
        riderNationalityIso:
            riders.length > 1 ? riders[1].nationalityIso : 'BEL',
        fromTeamId: null,
        fromTeamName: teamB,
        toTeamId: 'team_c',
        toTeamName: teamC,
        contractAmountEur: 920000,
        contractYears: 2,
        role: RiderRole.sprinter,
        newsType: TransferNewsType.biddingWarWon,
        expertComment:
            'Zacięta licytacja o jednego z najszybszych sprinterów peletonu zakończona sukcesem.',
        isBreakingNews: true,
      ),
      TransferNewsItem(
        id: 'ticker_fallback_3',
        date: now.subtract(const Duration(days: 1)),
        riderId: riders.length > 2 ? riders[2].id : 'r_3',
        riderName: rider3Name,
        riderNationalityIso:
            riders.length > 2 ? riders[2].nationalityIso : 'ITA',
        fromTeamId: null,
        fromTeamName: 'Wolny Agent',
        toTeamId: save.playerTeamId,
        toTeamName: teamA,
        contractAmountEur: 480000,
        contractYears: 2,
        role: RiderRole.superDomestique,
        newsType: TransferNewsType.freeAgentSigning,
        expertComment:
            'Wzmocnienie pociągu górskiego przed nadchodzącymi wyścigami etapowymi WorldTour.',
      ),
    ];
  }

  void _navigateToRoute(
    BuildContext context,
    String route,
    String fallbackSnackMessage,
  ) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(fallbackSnackMessage),
          backgroundColor: AppColors.surfaceLight,
        ),
      );
    }
  }

  void _openPreRaceBriefing(
    BuildContext context,
    TourRace race,
    RaceStage stage,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreRaceBriefingScreen(
          race: race,
          stage: stage,
          isStandalone: true,
        ),
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

  void _showTransferDetailDialog(
    BuildContext context,
    TransferNewsItem item,
  ) {
    showDialog<void>(
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
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.goldAccent,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${item.riderName} (${item.riderNationalityIso})',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
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
                  item.newsType.polishLabel.toUpperCase(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.cyanAccent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.fromTeamName} → ${item.toTeamName}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kontrakt: ${Formatters.formatCompactCurrency(item.contractAmountEur)}/rok • ${item.contractYears} lata • Rola: ${item.role.label}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Text(
                  item.expertComment,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                _navigateToRoute(
                  context,
                  AppRoutes.transfers,
                  'Otwarto Rynek Transferowy.',
                );
              },
              child: const Text('Rynek Transferowy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Zamknij'),
            ),
          ],
        );
      },
    );
  }

  void _showMessageDialog(
    BuildContext context,
    CareerInboxMessage msg,
    CareerStateNotifier notifier,
  ) {
    notifier.markMessageAsRead(msg.id);

    showDialog<void>(
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
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
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
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    Text(
                      _formatShortDate(msg.date),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppTheme.borderColor),
                const SizedBox(height: 8),
                Text(
                  msg.body,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
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

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
      final bike =
          (team?.teamBikes.isNotEmpty ?? false) ? team!.teamBikes.first : null;
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
        body:
            'Zarząd z uznaniem obserwuje postawę zespołu. Przypominamy, że premia €150k zostanie uruchomiona po ukończeniu Tour de France w pierwszej piątce.',
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
        body:
            'Mój klient czuje się doskonale w drużynie. Jesteśmy gotowi podpisać umowę na sezony 2027-2028 przy zachowaniu roli głównego lidera na Grand Toury.',
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
        body:
            'Wszyscy kluczowi liderzy pomyślnie zakończyli cykl zabiegów regeneracyjnych. Brak stanów zapalnych, gotowość do najbliższego etapu wynosi 100%.',
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
        body:
            'Zakończyliśmy inspekcję łańcuchów w kąpieli woskowej oraz przygotowaliśmy koła aero 65mm dla pociągu sprinterskiego.',
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
        return AppColors.crimsonAlert;
      case InboxCategory.raceBriefing:
      case InboxCategory.raceResults:
        return AppColors.statusSuccess;
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

  Color _parseHexColor(
    String hexString, [
    Color fallback = AppColors.primaryAccent,
  ]) {
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
    const months = [
      'sty',
      'lut',
      'mar',
      'kwi',
      'maj',
      'cze',
      'lip',
      'sie',
      'wrz',
      'paź',
      'lis',
      'gru',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatCompact(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).round()}k';
    return '$amount';
  }
}

// =============================================================================
// KOMPONENTY INTERAKTYWNE (HOVER / ACTIVE / FOCUS / DISABLED)
// =============================================================================

class _QuickActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String badgeText;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.badgeText,
    this.onTap,
  });
}

class _InteractiveQuickActionTile extends StatefulWidget {
  final _QuickActionItem item;

  const _InteractiveQuickActionTile({required this.item});

  @override
  State<_InteractiveQuickActionTile> createState() =>
      _InteractiveQuickActionTileState();
}

class _InteractiveQuickActionTileState
    extends State<_InteractiveQuickActionTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.item.onTap != null;
    final bool active = enabled && (_hovered || _focused || _pressed);

    return FocusableActionDetector(
      enabled: enabled,
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: enabled
          ? const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            }
          : null,
      actions: enabled
          ? <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  widget.item.onTap?.call();
                  return null;
                },
              ),
            }
          : null,
      child: GestureDetector(
        onTap: enabled ? widget.item.onTap : null,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.surfaceLight
                  : AppColors.surfaceLight.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? widget.item.accentColor : AppTheme.borderColor,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.item.accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: 16,
                    color: widget.item.accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        widget.item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: widget.item.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    widget.item.badgeText,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: widget.item.accentColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: active
                      ? widget.item.accentColor
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderStatusRow extends StatefulWidget {
  final Rider rider;
  final CyclingTeam team;
  final VoidCallback onOpenPdc;

  const _LeaderStatusRow({
    required this.rider,
    required this.team,
    required this.onOpenPdc,
  });

  @override
  State<_LeaderStatusRow> createState() => _LeaderStatusRowState();
}

class _LeaderStatusRowState extends State<_LeaderStatusRow> {
  bool _hovered = false;
  bool _focused = false;

  int _estimateDaysToPeak(double tsb, double recoveryRate) {
    if (tsb >= 10.0) return 0;
    final double deficit = 10.0 - tsb;
    final double dailyGain = (recoveryRate * 2.2).clamp(1.2, 4.5);
    return (deficit / dailyGain).ceil().clamp(1, 21);
  }

  @override
  Widget build(BuildContext context) {
    final rider = widget.rider;
    final bool isInjured = rider.health.currentInjury != null;
    final double tsb = rider.physiology.trainingStressBalanceTsb;
    final double morale = rider.contract.morale.clamp(0.0, 100.0);
    final int daysToPeak = _estimateDaysToPeak(tsb, rider.physiology.recoveryRate);
    final double wKg = rider.physiology.wattsPerKg;

    final Color tsbColor = tsb >= 10
        ? AppColors.statusSuccess
        : (tsb >= -5 ? AppColors.goldAccent : AppColors.crimsonAlert);
    final String tsbSign = tsb >= 0 ? '+' : '';
    final String peakLabel = isInjured
        ? 'Kontuzja (${rider.health.currentInjury!.daysRemaining}d)'
        : (daysToPeak == 0 ? 'Szczyt formy!' : '$daysToPeak dni do szczytu');

    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onOpenPdc,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (_hovered || _focused)
                  ? AppColors.goldAccent
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              RiderAvatarWidget(
                appearance: rider.appearance,
                team: widget.team,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          rider.lastName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            rider.specialization.name.toUpperCase(),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: AppColors.goldAccent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${rider.physiology.ftpWatts}W (${wKg.toStringAsFixed(1)} W/kg) • Morale ${morale.round()}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: morale / 100.0,
                        minHeight: 4,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(tsbColor),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: tsbColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: tsbColor.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      'TSB $tsbSign${tsb.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: tsbColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    peakLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: daysToPeak == 0 && !isInjured
                          ? AppColors.statusSuccess
                          : AppColors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
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
}

class _LineupRiderChip extends StatefulWidget {
  final Rider rider;
  final CyclingTeam team;
  final VoidCallback onTap;

  const _LineupRiderChip({
    required this.rider,
    required this.team,
    required this.onTap,
  });

  @override
  State<_LineupRiderChip> createState() => _LineupRiderChipState();
}

class _LineupRiderChipState extends State<_LineupRiderChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _focused;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceLight : AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.goldAccent : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RiderAvatarWidget(
                appearance: widget.rider.appearance,
                team: widget.team,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                widget.rider.lastName,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.rider.physiology.wattsPerKg.toStringAsFixed(1)}W/kg',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.cyanAccent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
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

class _PrimaryCtaButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isGold;
  final bool enabled;
  final VoidCallback? onPressed;

  const _PrimaryCtaButton({
    required this.label,
    required this.icon,
    required this.isGold,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_PrimaryCtaButton> createState() => _PrimaryCtaButtonState();
}

class _PrimaryCtaButtonState extends State<_PrimaryCtaButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = !widget.enabled
        ? AppColors.surfaceLight
        : (widget.isGold ? AppColors.goldAccent : AppColors.primaryAccent);
    final Color fgColor = !widget.enabled
        ? AppColors.textSecondary
        : (widget.isGold ? Colors.black : Colors.white);

    return FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor:
          widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hovered && widget.enabled
                  ? bgColor.withValues(alpha: 0.9)
                  : bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? Colors.white : Colors.transparent,
                width: 1.5,
              ),
              boxShadow: _hovered && widget.enabled
                  ? [
                      BoxShadow(
                        color: bgColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 17, color: fgColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: fgColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_SecondaryActionButton> createState() => _SecondaryActionButtonState();
}

class _SecondaryActionButtonState extends State<_SecondaryActionButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _focused;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceLight : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppColors.goldAccent : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: AppColors.goldAccent),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractiveTextToggle extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _InteractiveTextToggle({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_InteractiveTextToggle> createState() => _InteractiveTextToggleState();
}

class _InteractiveTextToggleState extends State<_InteractiveTextToggle> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _focused;
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active
                ? AppColors.cyanAccent.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? AppColors.cyanAccent : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 13, color: AppColors.cyanAccent),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.cyanAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HqIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  const _HqIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 34,
  });

  @override
  State<_HqIconButton> createState() => _HqIconButtonState();
}

class _HqIconButtonState extends State<_HqIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _hovered || _focused;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: active ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active ? AppColors.goldAccent : AppTheme.borderColor,
              ),
            ),
            child: Icon(
              widget.icon,
              size: widget.size * 0.54,
              color: AppColors.goldAccent,
            ),
          ),
        ),
      ),
    );
  }
}
