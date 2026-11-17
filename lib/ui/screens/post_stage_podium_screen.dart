import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/simulation/post_stage_recovery_processor.dart';
import '../../engine/simulation/stage_photo_album_auto_capturer.dart';
import '../../engine/simulation/stage_results_calculator.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/career/career_save.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../state/career_controller.dart';
import '../../state/race_simulation_notifier.dart';
import '../widgets/post_race_watts_per_kg_leaderboard_card.dart';
import '../widgets/post_stage_highlight_reel_carousel.dart';
import '../widgets/rider_avatar_painter.dart';

// Stałe kolorystyczne klasyfikacji UCI (Tour de France / Giro d'Italia / Vuelta a España)
const Color _goldJerseyGc = Color(0xFFFFD700);
const Color _greenJerseySprint = Color(0xFF10B981);
const Color _polkaDotRed = Color(0xFFEF4444);
const Color _whiteJerseyYouth = Color(0xFFF3F4F6);
const Color _teamJerseyYellow = Color(0xFFF59E0B);
const Color _podiumSilver = Color(0xFFCBD5E1);
const Color _podiumBronze = Color(0xFFB45309);
const Color _cardGlass = Color(0xFF181B22);
const Color _cardGlassLight = Color(0xFF222630);

/// Ekran podsumowania oficjalnych wyników etapu, podium i klasyfikacji wyścigu.
///
/// Zawiera 3 główne sekcje:
/// 1. Wyniki Etapu & Animowane Podium (Top 20 + wyróżnieni kolarze gracza),
/// 2. Klasyfikacje Wyścigu (Generalna GC, Punktowa, Górska KOM, Młodzieżowa U23, Drużynowa),
/// 3. Raport Medyczny, Fizjologiczny i Sprzętowy po etapie (wydatek energii, kraksy, premie finansowe, serwis rowerów).
class PostStagePodiumScreen extends ConsumerStatefulWidget {
  final StageSummaryReport? stageReport;
  final StageSimulationState? simulationState;
  final VoidCallback? onContinue;

  const PostStagePodiumScreen({
    super.key,
    this.stageReport,
    this.simulationState,
    this.onContinue,
  });

  @override
  ConsumerState<PostStagePodiumScreen> createState() => _PostStagePodiumScreenState();
}

class _PostStagePodiumScreenState extends ConsumerState<PostStagePodiumScreen>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  late TabController _classificationsTabController;

  // Kontrolery animacji podium
  late AnimationController _podiumAnimController;
  late Animation<double> _podiumScaleFirst;
  late Animation<double> _podiumScaleSecond;
  late Animation<double> _podiumScaleThird;

  // Filtr wyników etapu
  String _searchQuery = '';
  bool _onlyPlayerTeam = false;

  // Zapamiętany raport regeneracyjny
  PostStageRecoveryResult? _recoveryResult;
  bool _isProcessingRecovery = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 3, vsync: this);
    _classificationsTabController = TabController(length: 5, vsync: this);

    _podiumAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _podiumScaleSecond = CurvedAnimation(
      parent: _podiumAnimController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    );
    _podiumScaleThird = CurvedAnimation(
      parent: _podiumAnimController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
    );
    _podiumScaleFirst = CurvedAnimation(
      parent: _podiumAnimController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutBack),
    );

    _podiumAnimController.forward();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _classificationsTabController.dispose();
    _podiumAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(raceSimulationProvider);
    final careerUiState = ref.watch(careerProvider);
    final careerController = ref.read(careerProvider.notifier);

    final save = careerUiState.save;
    final playerTeamId = save?.playerTeamId ?? 'team_player';

    // 1. Ustalenie raportu etapu (przekazany parametr lub stan Riverpod lub fallback)
    final StageSummaryReport report = widget.stageReport ??
        simState.stageSummaryReport ??
        _generateFallbackStageReport(playerTeamId);

    // 2. Przeliczenie raportu regeneracyjnego i medycznego jeśli nie został wygenerowany
    if (_recoveryResult == null && save != null) {
      _calculateRecoveryResult(save, report, widget.simulationState ?? simState.simulationState);
    }

    // 3. Wyliczenie zaktualizowanych klasyfikacji wyścigu (GC, Punkty, KOM, U23, Drużynowa)
    final RaceClassifications classifications = _computeClassifications(
      report: report,
      save: save,
      playerTeamId: playerTeamId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(report),
      body: Column(
        children: [
          // Główny pasek zakładek
          _buildMainTabBar(),

          // Zawartość zakładek
          Expanded(
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // 1. Zakładka: Wyniki Etapu & Podium
                _buildStageResultsAndPodiumTab(report, playerTeamId, save),

                // 2. Zakładka: Klasyfikacje Wyścigu (GC, Punkty, KOM, Młodzieżowa, Team)
                _buildClassificationsTab(classifications, playerTeamId, save),

                // 3. Zakładka: Raport Medyczny, Fizjologiczny i Sprzętowy
                _buildMedicalAndEquipmentReportTab(report, playerTeamId, save),
              ],
            ),
          ),

          // Dolny pasek przejścia dalej
          _buildBottomActionBar(report, simState.simulationState, careerController),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAGŁÓWEK I GŁÓWNA NAWIGACJA
  // ===========================================================================

  PreferredSizeWidget _buildAppBar(StageSummaryReport report) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'CEREMONIA PODIUM UCI',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'Etap #${report.stageNumber}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            report.stageName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Chip(
            backgroundColor: AppColors.surfaceLight,
            side: const BorderSide(color: AppColors.cardBorder),
            avatar: const Icon(Icons.timer_outlined, size: 14, color: AppColors.cyanAccent),
            label: Text(
              _formatSecondsToTime(report.winnerTimeSeconds.round()),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: TabBar(
        controller: _mainTabController,
        indicatorColor: AppColors.goldAccent,
        indicatorWeight: 3,
        labelColor: AppColors.goldAccent,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(
            icon: Icon(Icons.emoji_events_rounded, size: 18),
            text: 'Wyniki Etapu & Podium',
          ),
          Tab(
            icon: Icon(Icons.leaderboard_rounded, size: 18),
            text: 'Klasyfikacje Wyścigu',
          ),
          Tab(
            icon: Icon(Icons.medical_services_rounded, size: 18),
            text: 'Raport Medyczny & Sprzęt',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 1: WYNIKI ETAPU & PODIUM
  // ===========================================================================

  Widget _buildStageResultsAndPodiumTab(
    StageSummaryReport report,
    String playerTeamId,
    CareerSave? save,
  ) {
    final top3 = report.results.take(3).toList();
    final allResults = report.results;

    // Filtrowanie listy wyników
    final filteredResults = allResults.where((res) {
      if (_onlyPlayerTeam && res.teamId != playerTeamId) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchRider = res.riderName.toLowerCase().contains(query);
        final matchTeam = res.teamId.toLowerCase().contains(query);
        if (!matchRider && !matchTeam) return false;
      }
      return true;
    }).toList();

    final albumState = ref.watch(stagePhotoAlbumProvider);
    final activeAlbum = albumState.activeAlbum;
    final reelItems = (activeAlbum != null && activeAlbum.photos.isNotEmpty)
        ? PostStageHighlightReelBuilder.fromStagePhotoAlbum(activeAlbum)
        : PostStageHighlightReelBuilder.buildDefaultSampleReel(
            stageNumber: report.stageNumber,
            stageName: report.stageName,
          );

    return CustomScrollView(
      slivers: [
        // 1. Animowana sekcja podium dla 3 najlepszych kolarzy
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: _buildPodiumStageWidget(top3, playerTeamId, save),
          ),
        ),

        // 1b. Karuzela skrótów wideo i zdjęć z etapu
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: PostStageHighlightReelCarousel(
              items: reelItems,
              stageTitle: report.stageName,
              stageNumber: report.stageNumber,
            ),
          ),
        ),

        // 2. Belka statystyk etapu i wyszukiwarki
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildStageResultsFilterBar(report, playerTeamId),
          ),
        ),

        // 3. Nagłówek tabeli wyników
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: _buildResultsTableHeader(),
          ),
        ),

        // 4. Lista wyników etapu (Top 20 + kolarze gracza)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final result = filteredResults[index];
                final isPlayerRider = result.teamId == playerTeamId;
                return _buildRiderResultRow(result, isPlayerRider, save);
              },
              childCount: filteredResults.length,
            ),
          ),
        ),
      ],
    );
  }

  /// Wizualizacja 3 stopni podium ceremonii medalowej
  Widget _buildPodiumStageWidget(
    List<OfficialRiderStageResult> top3,
    String playerTeamId,
    CareerSave? save,
  ) {
    if (top3.length < 3) return const SizedBox.shrink();

    final winner = top3[0];
    final second = top3[1];
    final third = top3[2];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGlass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_rounded, color: AppColors.goldAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'PODIUM ETAPOWE',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2. MIEJSCE (Srebro)
              Expanded(
                child: ScaleTransition(
                  scale: _podiumScaleSecond,
                  child: _buildPodiumPillar(
                    rank: 2,
                    result: second,
                    pillarHeight: 110,
                    pillarColor: const Color(0xFF334155),
                    accentColor: _podiumSilver,
                    isPlayer: second.teamId == playerTeamId,
                    save: save,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 1. MIEJSCE (Złoto / Zwycięzca)
              Expanded(
                child: ScaleTransition(
                  scale: _podiumScaleFirst,
                  child: _buildPodiumPillar(
                    rank: 1,
                    result: winner,
                    pillarHeight: 145,
                    pillarColor: const Color(0xFF3E3314),
                    accentColor: _goldJerseyGc,
                    isPlayer: winner.teamId == playerTeamId,
                    save: save,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // 3. MIEJSCE (Brąz)
              Expanded(
                child: ScaleTransition(
                  scale: _podiumScaleThird,
                  child: _buildPodiumPillar(
                    rank: 3,
                    result: third,
                    pillarHeight: 85,
                    pillarColor: const Color(0xFF2E1C12),
                    accentColor: _podiumBronze,
                    isPlayer: third.teamId == playerTeamId,
                    save: save,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar({
    required int rank,
    required OfficialRiderStageResult result,
    required double pillarHeight,
    required Color pillarColor,
    required Color accentColor,
    required bool isPlayer,
    required CareerSave? save,
  }) {
    final rider = save?.getRiderById(result.riderId);
    final team = save?.getTeamById(result.teamId);
    final teamName = team?.name ?? result.teamId;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Awatar kolarza
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: accentColor, width: rank == 1 ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: rank == 1 ? 16 : 8,
                    spreadRadius: rank == 1 ? 3 : 1,
                  ),
                ],
              ),
              child: rider != null
                  ? RiderAvatarWidget(
                      appearance: rider.appearance,
                      team: team,
                      size: rank == 1 ? 52 : 44,
                    )
                  : Icon(
                      Icons.person,
                      size: rank == 1 ? 32 : 26,
                      color: Colors.white70,
                    ),
            ),
            Positioned(
              bottom: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Nazwisko i team
        Text(
          result.riderName,
          style: TextStyle(
            color: isPlayer ? AppColors.goldAccent : AppColors.textPrimary,
            fontSize: rank == 1 ? 12.5 : 11,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          teamName,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Czas / strata
        Text(
          result.formattedGap,
          style: TextStyle(
            color: accentColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),

        // Słupek podium
        Container(
          height: pillarHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: pillarColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: Border.all(color: accentColor.withValues(alpha: 0.5)),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                accentColor.withValues(alpha: 0.25),
                pillarColor,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$rank',
                style: TextStyle(
                  color: accentColor,
                  fontSize: rank == 1 ? 32 : 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (result.prizeMoneyEur > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '€${result.prizeMoneyEur}',
                    style: const TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStageResultsFilterBar(StageSummaryReport report, String playerTeamId) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _cardGlass,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          // Pole wyszukiwania
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Szukaj kolarza lub ekipy...',
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  filled: true,
                  fillColor: _cardGlassLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Przełącznik "Tylko mój zespół"
          InkWell(
            onTap: () => setState(() => _onlyPlayerTeam = !_onlyPlayerTeam),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _onlyPlayerTeam ? AppColors.goldAccent : _cardGlassLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 16,
                    color: _onlyPlayerTeam ? Colors.black : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mój zespół',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _onlyPlayerTeam ? Colors.black : AppColors.textSecondary,
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

  Widget _buildResultsTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: [
          SizedBox(width: 34, child: Text('POZ', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text('KOLARZ / DRUŻYNA', style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
          SizedBox(width: 90, child: Text('CZAS / STRATA', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
          SizedBox(width: 44, child: Text('BONUS', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
          SizedBox(width: 48, child: Text('PUNKTY', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
          SizedBox(width: 62, child: Text('PREMIA', textAlign: TextAlign.right, style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRiderResultRow(
    OfficialRiderStageResult result,
    bool isPlayerRider,
    CareerSave? save,
  ) {
    final team = save?.getTeamById(result.teamId);
    final teamName = team?.name ?? result.teamId;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isPlayerRider ? AppColors.goldAccent.withValues(alpha: 0.12) : _cardGlass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPlayerRider ? AppColors.goldAccent.withValues(alpha: 0.5) : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          // Pozycja
          SizedBox(
            width: 34,
            child: Row(
              children: [
                if (result.rank <= 3)
                  Icon(
                    Icons.emoji_events,
                    size: 14,
                    color: result.rank == 1
                        ? _goldJerseyGc
                        : (result.rank == 2 ? _podiumSilver : _podiumBronze),
                  )
                else
                  Text(
                    '${result.rank}.',
                    style: TextStyle(
                      color: isPlayerRider ? AppColors.goldAccent : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // Kolarz & Drużyna
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 4,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      result.riderName,
                      style: TextStyle(
                        color: isPlayerRider ? AppColors.goldAccent : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isPlayerRider)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'TWÓJ KLUB',
                          style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                        ),
                      ),
                    if (result.isThreeKmRuleApplied)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.cyanAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          '3KM',
                          style: TextStyle(color: AppColors.cyanAccent, fontSize: 8, fontWeight: FontWeight.w800),
                        ),
                      ),
                  ],
                ),
                Text(
                  teamName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Czas / strata
          SizedBox(
            width: 90,
            child: Text(
              result.formattedGap,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: result.rank == 1 ? AppColors.goldAccent : AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Bonifikata (-10s / -6s / -4s)
          SizedBox(
            width: 44,
            child: Text(
              result.timeBonusSeconds > 0 ? '-${result.timeBonusSeconds}s' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: result.timeBonusSeconds > 0 ? AppColors.goldAccent : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Punkty zielona koszulka + KOM
          SizedBox(
            width: 48,
            child: Text(
              result.pointsGreenJersey > 0 ? '+${result.pointsGreenJersey}' : '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: result.pointsGreenJersey > 0 ? _greenJerseySprint : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Premia finansowa
          SizedBox(
            width: 62,
            child: Text(
              result.prizeMoneyEur > 0 ? '€${result.prizeMoneyEur}' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: result.prizeMoneyEur > 0 ? AppColors.emeraldGreen : AppColors.textSecondary,
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 2: KLASYFIKACJE WYŚCIGU (GC, PUNKTY, GÓRY, U23, DRUŻYNOWA)
  // ===========================================================================

  Widget _buildClassificationsTab(
    RaceClassifications classifications,
    String playerTeamId,
    CareerSave? save,
  ) {
    return Column(
      children: [
        // Podzakładki klasyfikacji UCI
        Container(
          color: _cardGlass,
          child: TabBar(
            controller: _classificationsTabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primaryGold,
            indicatorWeight: 2.5,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: '🟡 Generalna (GC)'),
              Tab(text: '🟢 Punktowa'),
              Tab(text: '🔴 Górska (KOM)'),
              Tab(text: '⚪ Młodzieżowa (U23)'),
              Tab(text: '👥 Drużynowa'),
            ],
          ),
        ),

        // Widoki list rankingowych poszczególnych klasyfikacji
        Expanded(
          child: TabBarView(
            controller: _classificationsTabController,
            children: [
              // 1. Generalna GC
              _buildClassificationListView(
                entries: classifications.generalClassification,
                playerTeamId: playerTeamId,
                jerseyColor: _goldJerseyGc,
                jerseyTitle: 'ŻÓŁTA KOSZULKA LIDERA (MAILLOT JAUNE)',
                isPoints: false,
                save: save,
              ),

              // 2. Punktowa
              _buildClassificationListView(
                entries: classifications.pointsClassification,
                playerTeamId: playerTeamId,
                jerseyColor: _greenJerseySprint,
                jerseyTitle: 'ZIELONA KOSZULKA PUNKTOWA (MAILLOT VERT)',
                isPoints: true,
                save: save,
              ),

              // 3. Górska KOM
              _buildClassificationListView(
                entries: classifications.mountainsClassification,
                playerTeamId: playerTeamId,
                jerseyColor: _polkaDotRed,
                jerseyTitle: 'KOSZULKA W GROCHY (KING OF THE MOUNTAINS)',
                isPoints: true,
                save: save,
              ),

              // 4. Młodzieżowa U23
              _buildClassificationListView(
                entries: classifications.youthClassification,
                playerTeamId: playerTeamId,
                jerseyColor: _whiteJerseyYouth,
                jerseyTitle: 'BIAŁA KOSZULKA NAJLEPSZEGO MŁODZIEŻOWCA (U23/U25)',
                isPoints: false,
                save: save,
              ),

              // 5. Drużynowa
              _buildTeamClassificationListView(
                entries: classifications.teamClassification,
                playerTeamId: playerTeamId,
                save: save,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationListView({
    required List<RiderClassificationEntry> entries,
    required String playerTeamId,
    required Color jerseyColor,
    required String jerseyTitle,
    required bool isPoints,
    required CareerSave? save,
  }) {
    if (entries.isEmpty) {
      return const Center(
        child: Text('Brak danych klasyfikacji.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }

    final leader = entries.first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Karta lidera klasyfikacji
        _buildLeaderJerseyCard(leader, jerseyColor, jerseyTitle, isPoints, save),
        const SizedBox(height: 16),

        // Lista kolejnych zawodników
        ...entries.map((entry) {
          final isPlayer = entry.teamId == playerTeamId;
          final team = save?.getTeamById(entry.teamId);
          final teamName = team?.name ?? entry.teamId;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPlayer ? AppColors.goldAccent.withValues(alpha: 0.12) : _cardGlass,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPlayer ? AppColors.goldAccent.withValues(alpha: 0.5) : AppTheme.borderColor,
              ),
            ),
            child: Row(
              children: [
                // Pozycja w klasyfikacji
                SizedBox(
                  width: 32,
                  child: Text(
                    '${entry.rank}.',
                    style: TextStyle(
                      color: entry.rank == 1 ? jerseyColor : (isPlayer ? AppColors.goldAccent : AppColors.textSecondary),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),

                // Kolarz i team
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            entry.riderName,
                            style: TextStyle(
                              color: isPlayer ? AppColors.goldAccent : AppColors.textPrimary,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isPlayer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.goldAccent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'TY',
                                style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        teamName,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                // Wynik: Czas / punkty
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isPoints ? '${entry.points} pkt' : _formatSecondsToTime(entry.totalTimeSeconds),
                      style: TextStyle(
                        color: entry.rank == 1 ? jerseyColor : AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (entry.rank > 1)
                      Text(
                        isPoints
                            ? '-${entries.first.points - entry.points} pkt'
                            : '+${_formatSecondsToTime(entry.timeBehindLeaderSeconds)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLeaderJerseyCard(
    RiderClassificationEntry leader,
    Color jerseyColor,
    String jerseyTitle,
    bool isPoints,
    CareerSave? save,
  ) {
    final team = save?.getTeamById(leader.teamId);
    final teamName = team?.name ?? leader.teamId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: jerseyColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: jerseyColor.withValues(alpha: 0.2),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Ikona koszulki lidera
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: jerseyColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: jerseyColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(Icons.checkroom_rounded, color: Colors.black87, size: 28),
          ),
          const SizedBox(width: 14),

          // Opis lidera
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jerseyTitle,
                  style: TextStyle(
                    color: jerseyColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  leader.riderName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  teamName,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),

          // Łączny wynik lidera
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('LIDER', style: TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold)),
              Text(
                isPoints ? '${leader.points} pkt' : _formatSecondsToTime(leader.totalTimeSeconds),
                style: TextStyle(
                  color: jerseyColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamClassificationListView({
    required List<TeamClassificationEntry> entries,
    required String playerTeamId,
    required CareerSave? save,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: entries.map((teamEntry) {
        final isPlayerTeam = teamEntry.teamId == playerTeamId;
        final team = save?.getTeamById(teamEntry.teamId);
        final teamName = team?.name ?? teamEntry.teamName;

        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isPlayerTeam ? AppColors.goldAccent.withValues(alpha: 0.12) : _cardGlass,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isPlayerTeam ? AppColors.goldAccent.withValues(alpha: 0.5) : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  '${teamEntry.rank}.',
                  style: TextStyle(
                    color: teamEntry.rank == 1 ? _teamJerseyYellow : (isPlayerTeam ? AppColors.goldAccent : AppColors.textSecondary),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      teamName,
                      style: TextStyle(
                        color: isPlayerTeam ? AppColors.goldAccent : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isPlayerTeam) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text('TWÓJ KLUB', style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatSecondsToTime(teamEntry.totalTimeSeconds),
                    style: TextStyle(
                      color: teamEntry.rank == 1 ? _teamJerseyYellow : AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (teamEntry.rank > 1)
                    Text(
                      '+${_formatSecondsToTime(teamEntry.timeBehindLeaderSeconds)}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ===========================================================================
  // ZAKŁADKA 3: RAPORT MEDYCZNY, FIZJOLOGICZNY I SPRZĘTOWY
  // ===========================================================================

  Widget _buildMedicalAndEquipmentReportTab(
    StageSummaryReport report,
    String playerTeamId,
    CareerSave? save,
  ) {
    final teamReport = _recoveryResult?.report;
    final int teamPrizeMoney = report.teamPrizeMoneyTotals[playerTeamId] ??
        report.results.where((r) => r.teamId == playerTeamId).fold<int>(0, (sum, r) => sum + r.prizeMoneyEur);

    final int ridersShareEur = (teamPrizeMoney * 0.70).round();
    final int clubShareEur = (teamPrizeMoney * 0.30).round();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Sekcja nagród finansowych z etapu (Prize Money Box)
        _buildPrizeMoneyBanner(teamPrizeMoney, ridersShareEur, clubShareEur),
        const SizedBox(height: 16),

        // 2. Kto stracił najwięcej energii (Zużycie glikogenu & Obciążenie TSS)
        _buildEnergyExpenditureSection(teamReport, save),
        const SizedBox(height: 16),

        // 2b. Najlepsze rekordy mocy dnia (5s / 1m / 5m / 20m) vs rekordy historyczne
        PostRaceWattsPerKgLeaderboardCard(
          data: PostRaceWattsPerKgLeaderboardData.fromStageReport(
            report: report,
            playerTeamId: playerTeamId,
            save: save,
          ),
        ),
        const SizedBox(height: 16),

        // 3. Raport medyczny: Kraksy, upadki i gabinet lekarza
        _buildMedicalInjuriesSection(teamReport, save),
        const SizedBox(height: 16),

        // 4. Raport sprzętowy i serwis rowerów
        _buildEquipmentWearSection(report),
      ],
    );
  }

  Widget _buildPrizeMoneyBanner(int totalPrizeEur, int ridersShare, int clubShare) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.emeraldGreen.withValues(alpha: 0.15),
            _cardGlass,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.monetization_on_rounded, color: AppColors.emeraldGreen, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'NAGRODY FINANSOWE ZA DZISIEJSZY ETAP',
                    style: TextStyle(
                      color: AppColors.emeraldGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Text(
                '€${_formatMoney(totalPrizeEur)}',
                style: const TextStyle(
                  color: AppColors.emeraldGreen,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPrizeSplitCard(
                  label: 'Kolarze & Obsługa (70%)',
                  amountEur: ridersShare,
                  description: 'Premie motywacyjne dla zawodników i mechaników',
                  icon: Icons.groups_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPrizeSplitCard(
                  label: 'Kasa Klubu (30%)',
                  amountEur: clubShare,
                  description: 'Zasilenie budżetu transferowego i R&D',
                  icon: Icons.account_balance_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeSplitCard({
    required String label,
    required int amountEur,
    required String description,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardGlassLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '€${_formatMoney(amountEur)}',
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
          ),
          Text(
            description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyExpenditureSection(TeamPostStageReport? teamReport, CareerSave? save) {
    final riderReports = teamReport?.riderReports ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: AppColors.amberWarning, size: 20),
              SizedBox(width: 8),
              Text(
                'WYDATEK ENERGETYCZNY & ZMĘCZENIE (TSS)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (riderReports.isEmpty)
            const Text(
              'Brak zarejestrowanych danych telemetrycznych dla zespołu.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            )
          else ...[
            ...riderReports.map((rReport) {
              final double tss = rReport.stageTss;
              final double tssFraction = (tss / 350.0).clamp(0.0, 1.0);
              Color tssColor = AppColors.emeraldGreen;
              if (tss > 240) {
                tssColor = AppColors.crimsonAlert;
              } else if (tss > 160) {
                tssColor = AppColors.amberWarning;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rReport.riderName,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'TSS: ${tss.round()} • Regeneracja: ${(rReport.overnightRecoveryScore * 100).round()}%',
                          style: TextStyle(color: tssColor, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: tssFraction,
                      backgroundColor: _cardGlassLight,
                      valueColor: AlwaysStoppedAnimation<Color>(tssColor),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      rReport.statusDescription,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalInjuriesSection(TeamPostStageReport? teamReport, CareerSave? save) {
    final crashedNames = teamReport?.crashedRiderNames ?? [];
    final injuredRiders = (teamReport?.riderReports ?? []).where((r) => r.activeInjury != null).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (crashedNames.isNotEmpty || injuredRiders.isNotEmpty)
              ? AppColors.crimsonAlert.withValues(alpha: 0.4)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.health_and_safety_rounded,
                color: injuredRiders.isNotEmpty ? AppColors.crimsonAlert : AppColors.emeraldGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'RAPORT MEDYCZNY & KRAKSY',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (crashedNames.isEmpty && injuredRiders.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: AppColors.emeraldGreen, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Brak kraks i urazów w zespole! Wszyscy kolarze ukończyli etap w pełni zdrowi.',
                      style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (crashedNames.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.crimsonAlert, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Udział w kraksie: ${crashedNames.join(", ")}',
                        style: const TextStyle(color: AppColors.crimsonAlert, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            ...injuredRiders.map((injReport) {
              final injury = injReport.activeInjury!;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _cardGlassLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.healing_rounded, color: AppColors.amberWarning, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${injReport.riderName}: ${injury.name}',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 11.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Czas leczenia: ${injReport.injuryDaysRemaining} dni • FTP na jutro: ${injReport.effectiveFtpNextStage}W',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: injury.trainingAllowed ? AppColors.amberWarning.withValues(alpha: 0.2) : AppColors.crimsonAlert.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        injury.trainingAllowed ? 'START MOŻLIWY' : 'NIEZDOLNY DO STARTU',
                        style: TextStyle(
                          color: injury.trainingAllowed ? AppColors.amberWarning : AppColors.crimsonAlert,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentWearSection(StageSummaryReport report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.build_circle_rounded, color: AppColors.cyanAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'RAPORT SPRZĘTOWY & SERWIS MECHANIKÓW',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildEquipmentStatPill(
                  title: 'Napęd i Łańcuch',
                  status: 'Wymaga kąpieli w wosku',
                  wearPercent: 0.28,
                  icon: Icons.sync_rounded,
                  color: AppColors.amberWarning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildEquipmentStatPill(
                  title: 'Klocki & Tarcze',
                  status: 'Stan optymalny (88%)',
                  wearPercent: 0.12,
                  icon: Icons.disc_full_rounded,
                  color: AppColors.emeraldGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildEquipmentStatPill(
                  title: 'Opony & Tubeless',
                  status: 'Ciśnienie OK, 0 mikronacięć',
                  wearPercent: 0.15,
                  icon: Icons.radio_button_checked_rounded,
                  color: AppColors.emeraldGreen,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildEquipmentStatPill(
                  title: 'Koła & Szprychy',
                  status: 'Wycentrowane na wozie',
                  wearPercent: 0.05,
                  icon: Icons.toll_rounded,
                  color: AppColors.cyanAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentStatPill({
    required String title,
    required String status,
    required double wearPercent,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _cardGlassLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (1.0 - wearPercent).clamp(0.0, 1.0),
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // DOLNY PASEK AKCJI
  // ===========================================================================

  Widget _buildBottomActionBar(
    StageSummaryReport report,
    StageSimulationState? simState,
    CareerController careerController,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Przycisk powrotu
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Zamknij', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 12),

            // Główny przycisk: Zastosuj regenerację i przejdź dalej
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessingRecovery
                    ? null
                    : () async {
                        setState(() => _isProcessingRecovery = true);
                        if (widget.onContinue != null) {
                          widget.onContinue!();
                        } else if (simState != null) {
                          await careerController.completeStageAndApplyRecovery(
                            stageSummary: report,
                            simulationState: simState,
                          );
                          if (mounted) {
                            Navigator.of(context).maybePop();
                          }
                        } else {
                          if (mounted) {
                            Navigator.of(context).maybePop();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isProcessingRecovery
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Icon(Icons.nightlight_round, size: 18),
                label: Text(
                  _isProcessingRecovery
                      ? 'PRZETWARZANIE REGENERACJI...'
                      : 'ZASTOSUJ REGENERACJĘ NOCNĄ & DALEJ 🏁',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // KALKULATORY I METODY POMOCNICZE
  // ===========================================================================

  void _calculateRecoveryResult(
    CareerSave save,
    StageSummaryReport report,
    StageSimulationState? simState,
  ) {
    try {
      final team = save.playerTeam;
      final teamRiders = save.playerRoster;

      _recoveryResult = PostStageRecoveryProcessor.processStageRecovery(
        teamRiders: teamRiders,
        team: team,
        stageNumber: report.stageNumber,
        officialResults: report.results,
        simulationState: simState,
        customFacilities: TeamRecoveryFacilities.fromTeam(team),
      );
    } catch (_) {
      // W razie braku pełnych obiektów symulacji zachowaj stabilność
    }
  }

  RaceClassifications _computeClassifications({
    required StageSummaryReport report,
    required CareerSave? save,
    required String playerTeamId,
  }) {
    // Sprawdź czy aktywny wyścig ma już zapisaną historię klasyfikacji
    final existingClass = save?.activeRace?.classifications;

    // 1. Klasyfikacja Generalna (GC)
    final List<RiderClassificationEntry> gc = [];
    final List<OfficialRiderStageResult> sortedByGc = List.from(report.results)
      ..sort((a, b) => a.officialFinishTimeSeconds.compareTo(b.officialFinishTimeSeconds));

    final double winnerTime = sortedByGc.isNotEmpty ? sortedByGc.first.officialFinishTimeSeconds : 14400.0;

    for (int i = 0; i < sortedByGc.length; i++) {
      final res = sortedByGc[i];
      final double totalSec = res.officialFinishTimeSeconds - res.timeBonusSeconds;
      final double gapSec = totalSec - (winnerTime - (sortedByGc.first.timeBonusSeconds));

      gc.add(
        RiderClassificationEntry(
          riderId: res.riderId,
          riderName: res.riderName,
          teamId: res.teamId,
          totalTimeSeconds: totalSec.round(),
          points: 0,
          rank: i + 1,
          timeBehindLeaderSeconds: math.max(0, gapSec.round()),
        ),
      );
    }

    // 2. Klasyfikacja Punktowa
    final List<RiderClassificationEntry> points = [];
    final List<OfficialRiderStageResult> sortedByPts = List.from(report.results)
      ..sort((a, b) => b.pointsGreenJersey.compareTo(a.pointsGreenJersey));

    for (int i = 0; i < sortedByPts.length; i++) {
      final res = sortedByPts[i];
      points.add(
        RiderClassificationEntry(
          riderId: res.riderId,
          riderName: res.riderName,
          teamId: res.teamId,
          totalTimeSeconds: 0,
          points: res.pointsGreenJersey > 0 ? res.pointsGreenJersey : math.max(1, 50 - i * 3),
          rank: i + 1,
          timeBehindLeaderSeconds: 0,
        ),
      );
    }

    // 3. Klasyfikacja Górska (KOM)
    final List<RiderClassificationEntry> kom = [];
    final List<OfficialRiderStageResult> sortedByKom = List.from(report.results)
      ..sort((a, b) => b.pointsKom.compareTo(a.pointsKom));

    for (int i = 0; i < sortedByKom.length; i++) {
      final res = sortedByKom[i];
      kom.add(
        RiderClassificationEntry(
          riderId: res.riderId,
          riderName: res.riderName,
          teamId: res.teamId,
          totalTimeSeconds: 0,
          points: res.pointsKom > 0 ? res.pointsKom : math.max(0, 30 - i * 2),
          rank: i + 1,
          timeBehindLeaderSeconds: 0,
        ),
      );
    }

    // 4. Klasyfikacja Młodzieżowa U23 / U25
    final List<RiderClassificationEntry> youth = [];
    int youthRank = 1;
    int? youthLeaderTime;

    for (final entry in gc) {
      final rider = save?.getRiderById(entry.riderId);
      final age = rider?.age ?? 23;
      if (age <= 25) {
        youthLeaderTime ??= entry.totalTimeSeconds;
        youth.add(
          entry.copyWith(
            rank: youthRank++,
            timeBehindLeaderSeconds: entry.totalTimeSeconds - youthLeaderTime,
          ),
        );
      }
    }

    // 5. Klasyfikacja Drużynowa (Team Classification)
    final Map<String, List<int>> teamTimesMap = {};
    for (final res in report.results) {
      teamTimesMap.putIfAbsent(res.teamId, () => []).add(res.officialFinishTimeSeconds.round());
    }

    final List<TeamClassificationEntry> teams = [];
    for (final entry in teamTimesMap.entries) {
      final times = entry.value..sort();
      final int top3Sum = times.take(3).fold<int>(0, (sum, t) => sum + t);
      final teamObj = save?.getTeamById(entry.key);
      teams.add(
        TeamClassificationEntry(
          teamId: entry.key,
          teamName: teamObj?.name ?? entry.key,
          totalTimeSeconds: top3Sum,
          rank: 1,
          timeBehindLeaderSeconds: 0,
        ),
      );
    }

    teams.sort((a, b) => a.totalTimeSeconds.compareTo(b.totalTimeSeconds));
    final int? bestTeamTime = teams.isNotEmpty ? teams.first.totalTimeSeconds : null;
    for (int i = 0; i < teams.length; i++) {
      teams[i] = teams[i].copyWith(
        rank: i + 1,
        timeBehindLeaderSeconds: bestTeamTime != null ? (teams[i].totalTimeSeconds - bestTeamTime) : 0,
      );
    }

    return existingClass ??
        RaceClassifications(
          generalClassification: gc,
          pointsClassification: points,
          mountainsClassification: kom,
          youthClassification: youth,
          teamClassification: teams,
        );
  }

  String _formatSecondsToTime(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00:00';
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatMoney(int amountEur) {
    return amountEur.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  // Fallbackowy raport etapu w przypadku podglądu ekranu bez aktywnej symulacji
  StageSummaryReport _generateFallbackStageReport(String playerTeamId) {
    const stageId = 'stage_sample_01';
    final List<OfficialRiderStageResult> sampleResults = [
      OfficialRiderStageResult(
        riderId: 'rider_pogacar',
        riderName: 'Tadej Pogačar',
        teamId: playerTeamId,
        rank: 1,
        rawFinishTimeSeconds: 14725.0,
        officialFinishTimeSeconds: 14725.0,
        timeBonusSeconds: 10,
        gapToWinnerSeconds: 0.0,
        pointsGreenJersey: 50,
        pointsKom: 20,
        prizeMoneyEur: 11000,
      ),
      const OfficialRiderStageResult(
        riderId: 'rider_vingegaard',
        riderName: 'Jonas Vingegaard',
        teamId: 'team_visma',
        rank: 2,
        rawFinishTimeSeconds: 14739.0,
        officialFinishTimeSeconds: 14739.0,
        timeBonusSeconds: 6,
        gapToWinnerSeconds: 14.0,
        pointsGreenJersey: 30,
        pointsKom: 15,
        prizeMoneyEur: 5500,
      ),
      const OfficialRiderStageResult(
        riderId: 'rider_evenepoel',
        riderName: 'Remco Evenepoel',
        teamId: 'team_soudal',
        rank: 3,
        rawFinishTimeSeconds: 14757.0,
        officialFinishTimeSeconds: 14757.0,
        timeBonusSeconds: 4,
        gapToWinnerSeconds: 32.0,
        pointsGreenJersey: 20,
        pointsKom: 10,
        prizeMoneyEur: 2800,
      ),
      const OfficialRiderStageResult(
        riderId: 'rider_roglig',
        riderName: 'Primož Roglič',
        teamId: 'team_bora',
        rank: 4,
        rawFinishTimeSeconds: 14770.0,
        officialFinishTimeSeconds: 14770.0,
        timeBonusSeconds: 0,
        gapToWinnerSeconds: 45.0,
        pointsGreenJersey: 18,
        pointsKom: 6,
        prizeMoneyEur: 1500,
      ),
      OfficialRiderStageResult(
        riderId: 'rider_majka',
        riderName: 'Rafał Majka',
        teamId: playerTeamId,
        rank: 5,
        rawFinishTimeSeconds: 14782.0,
        officialFinishTimeSeconds: 14782.0,
        timeBonusSeconds: 0,
        gapToWinnerSeconds: 57.0,
        pointsGreenJersey: 16,
        pointsKom: 4,
        prizeMoneyEur: 1200,
      ),
    ];

    return StageSummaryReport(
      stageId: stageId,
      stageNumber: 17,
      stageName: 'Saint-Gervais Mont-Blanc > Courchevel (Col de la Loze)',
      stageType: StageType.highMountain,
      winnerRiderName: 'Tadej Pogačar',
      winnerTeamId: playerTeamId,
      winnerTimeSeconds: 14725.0,
      timeCutLimitSeconds: 17670.0,
      timeCutPercent: 20.0,
      otlEliminatedCount: 0,
      dnfCount: 1,
      results: sampleResults,
      teamPrizeMoneyTotals: {
        playerTeamId: 12200,
        'team_visma': 5500,
        'team_soudal': 2800,
        'team_bora': 1500,
      },
    );
  }
}
