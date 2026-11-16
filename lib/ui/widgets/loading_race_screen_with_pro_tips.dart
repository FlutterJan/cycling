import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/diagnostics/asset_bundle_preload_warmer.dart';
import '../../core/theme/app_colors.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/stage_segment.dart';

/// Kategoria taktycznej porady dyrektora sportowego na ekranie ładowania.
enum TacticalProTipCategory {
  pelotonAndWind(
    label: 'Peleton i Wiatr',
    icon: Icons.air_rounded,
    accentColor: AppColors.accentBlue,
  ),
  climbingAndPacing(
    label: 'Góry i Tempo',
    icon: Icons.terrain_rounded,
    accentColor: AppColors.amberWarning,
  ),
  sprintingAndLeadout(
    label: 'Sprint i Pociąg',
    icon: Icons.bolt_rounded,
    accentColor: AppColors.goldAccent,
  ),
  nutritionAndHydration(
    label: 'Żywienie i Nawodnienie',
    icon: Icons.water_drop_rounded,
    accentColor: AppColors.statusSuccess,
  ),
  equipmentAndAero(
    label: 'Sprzęt i Aero',
    icon: Icons.settings_rounded,
    accentColor: AppColors.cyanAccent,
  ),
  raceRadioAndTactics(
    label: 'Radio i Taktyka',
    icon: Icons.headset_mic_rounded,
    accentColor: AppColors.primaryAccent,
  );

  final String label;
  final IconData icon;
  final Color accentColor;

  const TacticalProTipCategory({
    required this.label,
    required this.icon,
    required this.accentColor,
  });
}

/// Pojedyncza porada taktyczna dyrektora sportowego wyświetlana podczas ładowania wyścigu 3D.
class SportsDirectorProTip {
  final String id;
  final TacticalProTipCategory category;
  final String title;
  final String tipText;
  final String keyMetricBadge;

  const SportsDirectorProTip({
    required this.id,
    required this.category,
    required this.title,
    required this.tipText,
    required this.keyMetricBadge,
  });
}

/// Katalog autentycznych porad taktycznych dyrektora sportowego WorldTour.
class SportsDirectorProTipsCatalog {
  SportsDirectorProTipsCatalog._();

  static const List<SportsDirectorProTip> allTips = [
    SportsDirectorProTip(
      id: 'tip_drafting_core',
      category: TacticalProTipCategory.pelotonAndWind,
      title: 'Chronić lidera w środku peletonu',
      tipText:
          'Jazda w bezpiecznym środku grupy obniża opór aerodynamiczny aż o 35–48%. '
          'Na płaskich odcinkach trzymaj lidera na kole pomocnika, aby zachować pełną baterię W\' na finał.',
      keyMetricBadge: '-42% CdA',
    ),
    SportsDirectorProTip(
      id: 'tip_echelon_wind',
      category: TacticalProTipCategory.pelotonAndWind,
      title: 'Ranty przy wietrze bocznym > 35 km/h',
      tipText:
          'Gdy wiatr boczny przekracza 35 km/h na odsłoniętym terenie, ustaw drużynę w czołowej piętnastce '
          'przed zakrętem. Spóźniona reakcja oznacza pęknięcie peletonu i stratę minut w drugim rancie.',
      keyMetricBadge: 'Wiatr > 35 km/h',
    ),
    SportsDirectorProTip(
      id: 'tip_w_prime_skiba',
      category: TacticalProTipCategory.climbingAndPacing,
      title: 'Zarządzanie baterią beztlenową W\'',
      tipText:
          'Każdy atak powyżej progu FTP błyskawicznie drenuje rezerwę W\'. '
          'Zejście poniżej mocy krytycznej pozwala na wykładniczą regenerację — nie odpowiadaj na każdy zryw, jeśli masz mocnych pomocników.',
      keyMetricBadge: 'Skiba W\'bal',
    ),
    SportsDirectorProTip(
      id: 'tip_hypoxia_altitude',
      category: TacticalProTipCategory.climbingAndPacing,
      title: 'Hipoksja powyżej 2000 m n.p.m.',
      tipText:
          'Na przełęczach Hors Catégorie powyżej 2000 m spadek ciśnienia parcjalnego tlenu obniża realne FTP. '
          'Kolarze po obozie wysokogórskim lub pochodzący z Andów tracą znacznie mniej watów na szczycie.',
      keyMetricBadge: '> 2000 m n.p.m.',
    ),
    SportsDirectorProTip(
      id: 'tip_cadence_gearing',
      category: TacticalProTipCategory.climbingAndPacing,
      title: 'Kadencja na stromych ściankach > 15%',
      tipText:
          'Mielenie poniżej 60 RPM na zbyt twardym przełożeniu zwiększa zużycie glikogenu mięśniowego o +18%. '
          'Przed etapem górskim upewnij się, że mechanicy założyli kasetę 10-36T lub kompaktową korbę.',
      keyMetricBadge: 'Min. 70 RPM',
    ),
    SportsDirectorProTip(
      id: 'tip_sprint_slingshot',
      category: TacticalProTipCategory.sprintingAndLeadout,
      title: 'Proca aerodynamiczna na ostatnich 250 m',
      tipText:
          'Rozprowadzający powinien zejść ze zmiany na 250–300 m przed metą przy prędkości ok. 65 km/h. '
          'Sprinter wyskakujący z tunelu aero osiąga wtedy chwilowo 72–76 km/h dzięki opóźnionemu narastaniu oporu.',
      keyMetricBadge: '72–76 km/h',
    ),
    SportsDirectorProTip(
      id: 'tip_cobble_pressure',
      category: TacticalProTipCategory.equipmentAndAero,
      title: 'Ciśnienie opon na bruku 5★',
      tipText:
          'Na sektorach klasy Trouée d\'Arenberg obniż ciśnienie w oponach 30–32 mm do 3.8–4.2 bar. '
          'Zyskasz przyczepność i drastycznie zmniejszysz ryzyko przebicia kosztem minimalnie wyższych oporów na asfalcie.',
      keyMetricBadge: '3.8–4.2 BAR',
    ),
    SportsDirectorProTip(
      id: 'tip_hydration_heat',
      category: TacticalProTipCategory.nutritionAndHydration,
      title: 'Chłodzenie i elektrolity w upale',
      tipText:
          'Powyżej 39.2°C temperatury głębokiej spada maksymalna moc, a tętno dryfuje w górę. '
          'Wysyłaj pomocników po bidony i woreczki z lodem przed kluczowym podjazdem, aby uniknąć skurczów w końcówce.',
      keyMetricBadge: '< 39.0°C Core',
    ),
    SportsDirectorProTip(
      id: 'tip_bonk_prevention',
      category: TacticalProTipCategory.nutritionAndHydration,
      title: '90 g węglowodanów na godzinę',
      tipText:
          'Wyczerpanie glikogenu ("odcięcie prądu") redukuje moc kolarza do strefy Z1/Z2 aż do mety. '
          'Używaj żeli izotonicznych przed wjazdem na przełęcze Cat 1 i HC, zanim zapas spadnie poniżej 25%.',
      keyMetricBadge: '90g CHO/h',
    ),
    SportsDirectorProTip(
      id: 'tip_satellite_relay',
      category: TacticalProTipCategory.raceRadioAndTactics,
      title: 'Taktyka Stacji Przekaźnikowej',
      tipText:
          'Wyślij mocnego górala-pomocnika do porannej ucieczki. '
          'Na przedostatniej przełęczy wydaj rozkaz czekania na lidera GC, aby holował go w dolinie i u podnóża finałowego podjazdu.',
      keyMetricBadge: 'Relay +45s',
    ),
    SportsDirectorProTip(
      id: 'tip_supertuck_descent',
      category: TacticalProTipCategory.raceRadioAndTactics,
      title: 'Atak na technicznym zjeździe',
      tipText:
          'Kolarze z wysokim zjazdem i prowadzeniem roweru potrafią zyskać 25–45 sekund na 15 km serpentyn. '
          'W deszczu zmniejsz jednak agresję w zakrętach — mokry asfalt drastycznie obniża przyczepność.',
      keyMetricBadge: '25–45s zysku',
    ),
    SportsDirectorProTip(
      id: 'tip_grupetto_otl',
      category: TacticalProTipCategory.raceRadioAndTactics,
      title: 'Kontrola limitu czasu OTL w Grupetto',
      tipText:
          'Na morderczych etapach alpejskich Twoi sprinterzy muszą ukończyć etap w limicie czasu (zwykle +12–18%). '
          'Monitoruj baner OTL i w razie zagrożenia cofnij jednego pomocnika, by bezpiecznie dowieźć sprintera do mety.',
      keyMetricBadge: 'Limit OTL',
    ),
  ];

  /// Zwraca losową poradę z katalogu, opcjonalnie inną niż [excludeId].
  static SportsDirectorProTip pickRandom({
    math.Random? random,
    String? excludeId,
    TacticalProTipCategory? categoryFilter,
  }) {
    final rng = random ?? math.Random();
    final pool = categoryFilter == null
        ? allTips
        : allTips.where((t) => t.category == categoryFilter).toList();
    final candidates = excludeId == null || pool.length <= 1
        ? pool
        : pool.where((t) => t.id != excludeId).toList();
    if (candidates.isEmpty) return allTips.first;
    return candidates[rng.nextInt(candidates.length)];
  }
}

/// Ekran przejściowy ładowania wyścigu 3D z animowanym łańcuchem na zębatce,
/// paskiem postępu [AssetBundlePreloadWarmer], profilem wysokościowym etapu
/// oraz losowymi poradami taktycznymi dyrektora sportowego.
class LoadingRaceScreenWithProTips extends ConsumerStatefulWidget {
  /// Wczytywany etap wyścigu (jeśli null, prezentowany jest domyślny etap pokazowy).
  final RaceStage? stage;

  /// Zakres rozgrzewania zasobów 3D przez [AssetBundlePreloadWarmer].
  final GlbWarmupScope warmupScope;

  /// Czy uruchomić rozgrzewkę automatycznie po zamontowaniu ekranu.
  final bool autoStartWarmup;

  /// Czy automatycznie rotować porady taktyczne co kilka sekund.
  final bool autoRotateTips;

  /// Interwał rotacji porad taktycznych.
  final Duration tipRotationInterval;

  /// Czy wywołać [onReadyToEnterRace] automatycznie po zakończeniu ładowania.
  final bool autoProceedOnComplete;

  /// Opcjonalny seed RNG dla deterministycznego doboru pierwszej porady w testach.
  final int? randomSeed;

  /// Opcjonalne nadpisanie stanu [AssetBundlePreloadWarmer] (np. do testów UI / podglądu).
  final PreloadWarmupState? overrideWarmupState;

  /// Wywołane po kliknięciu przycisku wejścia do wyścigu 3D (lub auto-przejściu).
  final VoidCallback? onReadyToEnterRace;

  /// Wywołane po kliknięciu powrotu do odprawy przedstartowej.
  final VoidCallback? onCancelAndReturn;

  const LoadingRaceScreenWithProTips({
    super.key,
    this.stage,
    this.warmupScope = GlbWarmupScope.essentialBikesAndRace,
    this.autoStartWarmup = true,
    this.autoRotateTips = true,
    this.tipRotationInterval = const Duration(seconds: 6),
    this.autoProceedOnComplete = false,
    this.randomSeed,
    this.overrideWarmupState,
    this.onReadyToEnterRace,
    this.onCancelAndReturn,
  });

  @override
  ConsumerState<LoadingRaceScreenWithProTips> createState() =>
      _LoadingRaceScreenWithProTipsState();
}

class _LoadingRaceScreenWithProTipsState
    extends ConsumerState<LoadingRaceScreenWithProTips>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drivetrainController;
  late final math.Random _rng;
  late SportsDirectorProTip _currentTip;
  TacticalProTipCategory? _selectedCategoryFilter;
  Timer? _tipTimer;
  bool _isTipRotationPaused = false;
  bool _autoProceedTriggered = false;

  late final RaceStage _effectiveStage;

  @override
  void initState() {
    super.initState();
    _rng = math.Random(widget.randomSeed);
    _currentTip = SportsDirectorProTipsCatalog.pickRandom(random: _rng);
    _effectiveStage = widget.stage ?? _buildDefaultShowcaseStage();

    _drivetrainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    if (widget.autoRotateTips) {
      _startTipRotationTimer();
    }

    if (widget.autoStartWarmup && widget.overrideWarmupState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(preloadWarmupStateProvider.notifier);
        final current = ref.read(preloadWarmupStateProvider);
        if (!current.isRunning && !current.isWarmedUp) {
          notifier.selectScope(widget.warmupScope);
          unawaited(notifier.startWarmup());
        } else if (current.isWarmedUp &&
            widget.autoProceedOnComplete &&
            !_autoProceedTriggered) {
          _autoProceedTriggered = true;
          widget.onReadyToEnterRace?.call();
        }
      });
    }
  }

  void _startTipRotationTimer() {
    _tipTimer?.cancel();
    _tipTimer = Timer.periodic(widget.tipRotationInterval, (_) {
      if (!mounted || _isTipRotationPaused) return;
      _selectNextRandomTip();
    });
  }

  void _selectNextRandomTip() {
    setState(() {
      _currentTip = SportsDirectorProTipsCatalog.pickRandom(
        random: _rng,
        excludeId: _currentTip.id,
        categoryFilter: _selectedCategoryFilter,
      );
    });
  }

  void _selectPreviousTip() {
    final pool = _selectedCategoryFilter == null
        ? SportsDirectorProTipsCatalog.allTips
        : SportsDirectorProTipsCatalog.allTips
            .where((t) => t.category == _selectedCategoryFilter)
            .toList();
    if (pool.isEmpty) return;
    final idx = pool.indexWhere((t) => t.id == _currentTip.id);
    final prevIdx = idx <= 0 ? pool.length - 1 : idx - 1;
    setState(() {
      _currentTip = pool[prevIdx];
    });
  }

  void _toggleTipRotationPause() {
    setState(() {
      _isTipRotationPaused = !_isTipRotationPaused;
    });
  }

  void _setCategoryFilter(TacticalProTipCategory? category) {
    setState(() {
      _selectedCategoryFilter =
          _selectedCategoryFilter == category ? null : category;
      _currentTip = SportsDirectorProTipsCatalog.pickRandom(
        random: _rng,
        excludeId: _currentTip.id,
        categoryFilter: _selectedCategoryFilter,
      );
    });
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _drivetrainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PreloadWarmupState warmupState =
        widget.overrideWarmupState ?? ref.watch(preloadWarmupStateProvider);

    if (widget.autoProceedOnComplete &&
        warmupState.isWarmedUp &&
        !warmupState.isRunning &&
        !_autoProceedTriggered) {
      _autoProceedTriggered = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onReadyToEnterRace?.call();
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final isMobile = width < 700;
            final isDesktop = width >= 1200;

            return Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.45),
                  radius: 1.25,
                  colors: [
                    Color(0xFF1A1E29),
                    AppColors.background,
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : (isDesktop ? 32 : 24),
                  vertical: isMobile ? 14 : 22,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 1360 : 1040,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopStageBanner(isMobile),
                        SizedBox(height: isMobile ? 14 : 20),
                        if (isDesktop)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 5,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildDrivetrainAndWarmupCard(
                                      warmupState,
                                      isMobile: false,
                                    ),
                                    const SizedBox(height: 18),
                                    _buildActionButtonsRow(
                                      warmupState,
                                      isMobile: false,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildElevationProfileCard(isMobile: false),
                                    const SizedBox(height: 18),
                                    _buildProTipsCard(isMobile: false),
                                  ],
                                ),
                              ),
                            ],
                          )
                        else ...[
                          _buildDrivetrainAndWarmupCard(
                            warmupState,
                            isMobile: isMobile,
                          ),
                          SizedBox(height: isMobile ? 14 : 18),
                          _buildElevationProfileCard(isMobile: isMobile),
                          SizedBox(height: isMobile ? 14 : 18),
                          _buildProTipsCard(isMobile: isMobile),
                          SizedBox(height: isMobile ? 16 : 20),
                          _buildActionButtonsRow(
                            warmupState,
                            isMobile: isMobile,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopStageBanner(bool isMobile) {
    final stage = _effectiveStage;
    final stageTypeLabel = _stageTypeLabel(stage.stageType);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryAccent.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  'ETAP ${stage.stageNumber}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.goldAccent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stage.name,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Przygotowanie silnika 3D i telemetrii wyścigu',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StageMetricPill(
                icon: Icons.route_rounded,
                label: '${stage.totalDistanceKm.toStringAsFixed(1)} km',
                color: AppColors.accentBlue,
              ),
              _StageMetricPill(
                icon: Icons.trending_up_rounded,
                label: '+${stage.totalElevationGainM.round()} m',
                color: AppColors.amberWarning,
              ),
              _StageMetricPill(
                icon: Icons.landscape_rounded,
                label: stageTypeLabel,
                color: AppColors.goldAccent,
              ),
              _StageMetricPill(
                icon: _weatherIcon(stage.weatherCondition),
                label:
                    '${stage.baseTemperatureCelsius.round()}°C • ${stage.windSpeedKmh.round()} km/h',
                color: AppColors.cyanAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrivetrainAndWarmupCard(
    PreloadWarmupState warmupState, {
    required bool isMobile,
  }) {
    final progress = warmupState.progress.clamp(0.0, 1.0);
    final percentText = '${(progress * 100).round()}%';
    final isFailed = warmupState.phase == PreloadWarmupPhase.failed;
    final isDone = warmupState.isWarmedUp && !warmupState.isRunning;

    final Color barAccent = isFailed
        ? AppColors.crimsonAlert
        : (isDone ? AppColors.statusSuccess : AppColors.goldAccent);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'NAPĘD SILNIKA 3D',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: barAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: barAccent.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    warmupState.phase.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: barAccent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: isMobile ? 150 : 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AnimatedBuilder(
                animation: _drivetrainController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: AnimatedChainringAndChainPainter(
                      animationValue: _drivetrainController.value,
                      loadProgress: progress,
                      isCompleted: isDone,
                      isError: isFailed,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  warmupState.currentTaskLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                percentText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: barAccent,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              color: AppColors.surfaceLight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: progress),
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  builder: (context, animatedProgress, _) {
                    return FractionallySizedBox(
                      widthFactor: animatedProgress.clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isFailed
                                ? const [
                                    AppColors.crimsonAlert,
                                    Color(0xFFF87171),
                                  ]
                                : isDone
                                    ? const [
                                        AppColors.statusSuccess,
                                        Color(0xFF34D399),
                                      ]
                                    : const [
                                        AppColors.primaryAccent,
                                        AppColors.goldAccent,
                                      ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WarmupPhasePill(
                stepNumber: '1',
                label: 'Shadery Canvas',
                isActive: warmupState.phase == PreloadWarmupPhase.shaders,
                isDone: progress >= 0.34 || isDone,
              ),
              _WarmupPhasePill(
                stepNumber: '2',
                label: 'Siatki .glb 3D',
                isActive: warmupState.phase == PreloadWarmupPhase.glbMeshes,
                isDone: progress >= 0.72 || isDone,
              ),
              _WarmupPhasePill(
                stepNumber: '3',
                label: 'Glify Inter',
                isActive: warmupState.phase == PreloadWarmupPhase.fontsAndText,
                isDone: isDone,
              ),
            ],
          ),
          if (warmupState.lastReport != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: Text(
                warmupState.lastReport!.summaryText,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
          if (isFailed) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.crimsonAlert.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.crimsonAlert.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.crimsonAlert,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warmupState.errorMessage ??
                          'Nie udało się w pełni rozgrzać zasobów.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _InteractiveChipButton(
                    label: 'Ponów',
                    icon: Icons.refresh_rounded,
                    accentColor: AppColors.crimsonAlert,
                    onTap: widget.overrideWarmupState != null
                        ? null
                        : () {
                            unawaited(
                              ref
                                  .read(preloadWarmupStateProvider.notifier)
                                  .startWarmup(force: true),
                            );
                          },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildElevationProfileCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.area_chart_rounded,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'PROFIL WYSOKOŚCIOWY ETAPU',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Max ${_effectiveStage.maxElevationM.round()} m n.p.m.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: isMobile ? 140 : 175,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
            ),
            padding: const EdgeInsets.all(10),
            child: CustomPaint(
              painter: _StageLoadingElevationPainter(stage: _effectiveStage),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProTipsCard({required bool isMobile}) {
    final tip = _currentTip;
    final accent = tip.category.accentColor;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.headset_mic_rounded,
                      size: 16,
                      color: AppColors.goldAccent,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'PORADA DYREKTORA SPORTOWEGO',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _IconActionButton(
                    tooltip: 'Poprzednia porada',
                    icon: Icons.chevron_left_rounded,
                    onTap: _selectPreviousTip,
                  ),
                  const SizedBox(width: 6),
                  _IconActionButton(
                    tooltip: _isTipRotationPaused
                        ? 'Wznów automatyczną rotację'
                        : 'Wstrzymaj automatyczną rotację',
                    icon: _isTipRotationPaused
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    isActive: _isTipRotationPaused,
                    onTap: _toggleTipRotationPause,
                  ),
                  const SizedBox(width: 6),
                  _IconActionButton(
                    tooltip: 'Losuj kolejną poradę',
                    icon: Icons.shuffle_rounded,
                    onTap: _selectNextRandomTip,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: TacticalProTipCategory.values.map((cat) {
                final isSelected = _selectedCategoryFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _InteractiveChipButton(
                    label: cat.label,
                    icon: cat.icon,
                    accentColor: cat.accentColor,
                    isSelected: isSelected,
                    onTap: () => _setCategoryFilter(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: Container(
              key: ValueKey<String>(tip.id),
              padding: EdgeInsets.all(isMobile ? 14 : 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                  width: 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tip.category.icon, size: 18, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tip.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          tip.keyMetricBadge,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldAccent,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tip.tipText,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textSecondary,
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

  Widget _buildActionButtonsRow(
    PreloadWarmupState warmupState, {
    required bool isMobile,
  }) {
    final canEnterRace = warmupState.isWarmedUp && !warmupState.isRunning;

    final backButton = _PrimaryActionButton(
      label: 'Wróć do Odprawy',
      icon: Icons.arrow_back_rounded,
      isPrimary: false,
      isEnabled: true,
      onPressed: widget.onCancelAndReturn ?? () => Navigator.maybePop(context),
    );

    final startButton = _PrimaryActionButton(
      label: canEnterRace
          ? 'Wejdź do Wyścigu 3D'
          : 'Ładowanie zasobów 3D...',
      icon: canEnterRace ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
      isPrimary: true,
      isEnabled: canEnterRace,
      onPressed: canEnterRace ? widget.onReadyToEnterRace : null,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          startButton,
          const SizedBox(height: 10),
          backButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: backButton),
        const SizedBox(width: 14),
        Expanded(flex: 2, child: startButton),
      ],
    );
  }

  static String _stageTypeLabel(StageType type) {
    switch (type) {
      case StageType.flat:
        return 'Płaski';
      case StageType.hilly:
        return 'Pagórkowaty';
      case StageType.highMountain:
        return 'Wysokogórski';
      case StageType.summitFinish:
        return 'Meta na Szczycie';
      case StageType.individualTimeTrial:
        return 'Jazda na Czas (ITT)';
      case StageType.teamTimeTrial:
        return 'Drużynowa (TTT)';
      case StageType.cobbleClassic:
        return 'Klasyk Brukowy';
    }
  }

  static IconData _weatherIcon(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.sunny:
        return Icons.wb_sunny_rounded;
      case WeatherCondition.overcast:
        return Icons.cloud_rounded;
      case WeatherCondition.lightRain:
      case WeatherCondition.heavyStorm:
        return Icons.grain_rounded;
      case WeatherCondition.crosswindGale:
        return Icons.air_rounded;
      case WeatherCondition.extremeHeat:
        return Icons.thermostat_rounded;
    }
  }

  static RaceStage _buildDefaultShowcaseStage() {
    return const RaceStage(
      id: 'showcase_alpe_dhuez',
      stageNumber: 15,
      name: "Bourg-d'Oisans → Alpe d'Huez",
      stageType: StageType.summitFinish,
      baseTemperatureCelsius: 24.0,
      weatherCondition: WeatherCondition.sunny,
      windSpeedKmh: 14.0,
      segments: [
        StageSegment(
          index: 0,
          startKm: 0.0,
          lengthKm: 32.0,
          startElevationM: 720.0,
          endElevationM: 780.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 18.0,
          windDirectionDegrees: 180.0,
          roadBearingDegrees: 90.0,
          sprintOrKomClassification: SegmentClassification.intermediateSprint,
        ),
        StageSegment(
          index: 1,
          startKm: 32.0,
          lengthKm: 22.0,
          startElevationM: 780.0,
          endElevationM: 2067.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 62.0,
          windDirectionDegrees: 220.0,
          roadBearingDegrees: 120.0,
          sprintOrKomClassification: SegmentClassification.horsCategorie,
        ),
        StageSegment(
          index: 2,
          startKm: 54.0,
          lengthKm: 28.0,
          startElevationM: 2067.0,
          endElevationM: 725.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 75.0,
          windDirectionDegrees: 200.0,
          roadBearingDegrees: 180.0,
          sprintOrKomClassification: SegmentClassification.none,
        ),
        StageSegment(
          index: 3,
          startKm: 82.0,
          lengthKm: 13.8,
          startElevationM: 725.0,
          endElevationM: 1850.0,
          surfaceType: SegmentSurfaceType.smoothAsphalt,
          technicalDifficulty: 68.0,
          windDirectionDegrees: 190.0,
          roadBearingDegrees: 45.0,
          sprintOrKomClassification: SegmentClassification.finishLine,
        ),
      ],
    );
  }
}

/// CustomPainter rysujący animowaną zębatkę korby, tylną kasetę i przesuwający się łańcuch rowerowy.
class AnimatedChainringAndChainPainter extends CustomPainter {
  final double animationValue;
  final double loadProgress;
  final bool isCompleted;
  final bool isError;

  const AnimatedChainringAndChainPainter({
    required this.animationValue,
    required this.loadProgress,
    this.isCompleted = false,
    this.isError = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerY = h * 0.52;

    final frontCenter = Offset(w * 0.62, centerY);
    final frontRadius = math.min(h * 0.34, w * 0.16);
    final rearCenter = Offset(w * 0.24, centerY + frontRadius * 0.12);
    final rearRadius = frontRadius * 0.46;

    final accentColor = isError
        ? AppColors.crimsonAlert
        : (isCompleted ? AppColors.statusSuccess : AppColors.goldAccent);

    // Subtelna siatka tła i poświata za napędem
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: frontCenter, radius: frontRadius * 1.9),
      );
    canvas.drawCircle(frontCenter, frontRadius * 1.9, glowPaint);

    // Kąt obrotu zębatek
    final frontAngle = animationValue * 2 * math.pi;
    final rearAngle = frontAngle * (frontRadius / rearRadius);

    // Rysuj tylną kasetę
    _drawSprocket(
      canvas: canvas,
      center: rearCenter,
      radius: rearRadius,
      teethCount: 14,
      rotation: rearAngle,
      ringColor: const Color(0xFF4B5563),
      accentColor: accentColor,
      isChainring: false,
    );

    // Rysuj przednią zębatkę korby (52T stylizowana)
    _drawSprocket(
      canvas: canvas,
      center: frontCenter,
      radius: frontRadius,
      teethCount: 28,
      rotation: frontAngle,
      ringColor: const Color(0xFF9CA3AF),
      accentColor: accentColor,
      isChainring: true,
    );

    // Rysuj zamkniętą pętlę łańcucha rowerowego wokół obu zębatek
    _drawAnimatedChainLoop(
      canvas: canvas,
      rearCenter: rearCenter,
      rearRadius: rearRadius,
      frontCenter: frontCenter,
      frontRadius: frontRadius,
      phase: animationValue,
      accentColor: accentColor,
    );

    // Ramię korby
    canvas.save();
    canvas.translate(frontCenter.dx, frontCenter.dy);
    canvas.rotate(frontAngle);
    final crankPaint = Paint()
      ..color = const Color(0xFF111318)
      ..style = PaintingStyle.fill;
    final crankBorder = Paint()
      ..color = accentColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final crankRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(-7, -6, frontRadius * 1.15, 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(crankRect, crankPaint);
    canvas.drawRRect(crankRect, crankBorder);
    canvas.drawCircle(
      Offset(frontRadius * 1.02, 0),
      4.5,
      Paint()..color = accentColor,
    );
    canvas.restore();
  }

  void _drawSprocket({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required int teethCount,
    required double rotation,
    required Color ringColor,
    required Color accentColor,
    required bool isChainring,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final teethPath = Path();
    final outerR = radius + (isChainring ? 4.5 : 3.2);
    final innerR = radius - 1.5;

    for (var i = 0; i < teethCount; i++) {
      final a0 = (i / teethCount) * 2 * math.pi;
      final a1 = ((i + 0.35) / teethCount) * 2 * math.pi;
      final a2 = ((i + 0.65) / teethCount) * 2 * math.pi;
      final a3 = ((i + 1.0) / teethCount) * 2 * math.pi;

      final p0 = Offset(math.cos(a0) * innerR, math.sin(a0) * innerR);
      final p1 = Offset(math.cos(a1) * outerR, math.sin(a1) * outerR);
      final p2 = Offset(math.cos(a2) * outerR, math.sin(a2) * outerR);
      final p3 = Offset(math.cos(a3) * innerR, math.sin(a3) * innerR);

      if (i == 0) {
        teethPath.moveTo(p0.dx, p0.dy);
      } else {
        teethPath.lineTo(p0.dx, p0.dy);
      }
      teethPath.lineTo(p1.dx, p1.dy);
      teethPath.lineTo(p2.dx, p2.dy);
      teethPath.lineTo(p3.dx, p3.dy);
    }
    teethPath.close();

    canvas.drawPath(
      teethPath,
      Paint()
        ..color = ringColor.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      teethPath,
      Paint()
        ..color = ringColor.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    if (isChainring) {
      // Wycięcia pająka korby (4 ramiona)
      final spiderPaint = Paint()
        ..color = AppColors.surfaceLight
        ..style = PaintingStyle.fill;
      for (var arm = 0; arm < 4; arm++) {
        final baseAngle = arm * (math.pi / 2) + 0.25;
        final cutout = Path()
          ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.72),
            baseAngle,
            math.pi / 2 - 0.5,
            true,
          )
          ..arcTo(
            Rect.fromCircle(center: Offset.zero, radius: radius * 0.34),
            baseAngle + math.pi / 2 - 0.5,
            -(math.pi / 2 - 0.5),
            false,
          )
          ..close();
        canvas.drawPath(cutout, spiderPaint);
      }

      // Śruba centralna
      canvas.drawCircle(
        Offset.zero,
        radius * 0.19,
        Paint()..color = const Color(0xFF181B22),
      );
      canvas.drawCircle(
        Offset.zero,
        radius * 0.19,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    } else {
      canvas.drawCircle(
        Offset.zero,
        radius * 0.32,
        Paint()..color = AppColors.surfaceLight,
      );
      canvas.drawCircle(
        Offset.zero,
        radius * 0.32,
        Paint()
          ..color = accentColor.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    canvas.restore();
  }

  void _drawAnimatedChainLoop({
    required Canvas canvas,
    required Offset rearCenter,
    required double rearRadius,
    required Offset frontCenter,
    required double frontRadius,
    required double phase,
    required Color accentColor,
  }) {
    final rearR = rearRadius + 2.0;
    final frontR = frontRadius + 2.5;

    final path = Path();
    // Górna prosta łańcucha (od tylnej kasety do przedniej zębatki)
    final topRear = Offset(rearCenter.dx, rearCenter.dy - rearR);
    final topFront = Offset(frontCenter.dx, frontCenter.dy - frontR);
    final botFront = Offset(frontCenter.dx, frontCenter.dy + frontR);
    final botRear = Offset(rearCenter.dx, rearCenter.dy + rearR);

    path.moveTo(topRear.dx, topRear.dy);
    path.lineTo(topFront.dx, topFront.dy);
    path.arcToPoint(
      botFront,
      radius: Radius.circular(frontR),
      clockwise: true,
    );
    path.lineTo(botRear.dx, botRear.dy);
    path.arcToPoint(
      topRear,
      radius: Radius.circular(rearR),
      clockwise: true,
    );
    path.close();

    // Bazowy tor łańcucha
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF374151)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2,
    );

    // Animowane ogniwa łańcucha przesuwające się po ścieżce
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final totalLength = metric.length;
    const linkPitch = 11.0;
    final linkCount = (totalLength / linkPitch).floor().clamp(8, 120);
    final offsetPx = (phase * linkPitch * 6) % totalLength;

    final linkPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final pinPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < linkCount; i++) {
      final dist = (i * linkPitch + offsetPx) % totalLength;
      final endDist = (dist + linkPitch * 0.58) % totalLength;
      if (endDist > dist) {
        final segment = metric.extractPath(dist, endDist);
        canvas.drawPath(segment, linkPaint);
      }
      final tangent = metric.getTangentForOffset(dist);
      if (tangent != null) {
        canvas.drawCircle(tangent.position, 1.4, pinPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedChainringAndChainPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.loadProgress != loadProgress ||
        oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isError != isError;
  }
}

class _StageMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StageMetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmupPhasePill extends StatelessWidget {
  final String stepNumber;
  final String label;
  final bool isActive;
  final bool isDone;

  const _WarmupPhasePill({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isDone
        ? AppColors.statusSuccess
        : (isActive ? AppColors.goldAccent : const Color(0xFF2A2F3D));
    final Color bgColor = isDone
        ? AppColors.statusSuccess.withValues(alpha: 0.14)
        : (isActive
            ? AppColors.goldAccent.withValues(alpha: 0.14)
            : AppColors.surfaceLight);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDone
                ? Icons.check_circle_rounded
                : (isActive
                    ? Icons.autorenew_rounded
                    : Icons.radio_button_unchecked_rounded),
            size: 14,
            color: isDone
                ? AppColors.statusSuccess
                : (isActive ? AppColors.goldAccent : AppColors.textSecondary),
          ),
          const SizedBox(width: 6),
          Text(
            '$stepNumber. $label',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
              color: isDone || isActive
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final bool isActive;
  final VoidCallback? onTap;

  const _IconActionButton({
    required this.tooltip,
    required this.icon,
    this.isActive = false,
    this.onTap,
  });

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final borderColor = widget.isActive || _isFocused
        ? AppColors.goldAccent
        : (_isHovered ? const Color(0xFF4B5563) : const Color(0xFF2A2F3D));
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : (_isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : (_isHovered || widget.isActive
                ? AppColors.surfaceLight
                : AppColors.background));

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              enabled ? () => setState(() => _isPressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color: !enabled
                  ? AppColors.textSecondary.withValues(alpha: 0.4)
                  : (widget.isActive
                      ? AppColors.goldAccent
                      : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveChipButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const _InteractiveChipButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<_InteractiveChipButton> createState() => _InteractiveChipButtonState();
}

class _InteractiveChipButtonState extends State<_InteractiveChipButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final borderColor = widget.isSelected || _isFocused
        ? widget.accentColor
        : (_isHovered
            ? widget.accentColor.withValues(alpha: 0.6)
            : const Color(0xFF2A2F3D));
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.2)
            : (_isPressed
                ? widget.accentColor.withValues(alpha: 0.28)
                : (_isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background));

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: enabled
                    ? widget.accentColor
                    : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isEnabled,
    this.onPressed,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled && widget.onPressed != null;

    Color bgColor;
    Color borderColor;
    Color textColor;

    if (!enabled) {
      bgColor = AppColors.surfaceLight.withValues(alpha: 0.45);
      borderColor = const Color(0xFF2A2F3D);
      textColor = AppColors.textSecondary.withValues(alpha: 0.55);
    } else if (widget.isPrimary) {
      bgColor = _isPressed
          ? const Color(0xFF723736)
          : (_isHovered ? const Color(0xFFA25857) : AppColors.primaryAccent);
      borderColor = _isFocused ? AppColors.goldAccent : AppColors.goldAccent.withValues(alpha: 0.7);
      textColor = AppColors.textPrimary;
    } else {
      bgColor = _isPressed
          ? AppColors.surfaceLight
          : (_isHovered ? const Color(0xFF282D3A) : AppColors.surface);
      borderColor = _isFocused ? AppColors.goldAccent : const Color(0xFF2A2F3D);
      textColor = AppColors.textPrimary;
    }

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.isPrimary && enabled
                    ? AppColors.goldAccent
                    : textColor,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageLoadingElevationPainter extends CustomPainter {
  final RaceStage stage;

  const _StageLoadingElevationPainter({required this.stage});

  @override
  void paint(Canvas canvas, Size size) {
    final segments = stage.segments;
    if (segments.isEmpty) return;

    const padLeft = 8.0;
    const padRight = 8.0;
    const padTop = 18.0;
    const padBottom = 22.0;

    final chartW = math.max(1.0, size.width - padLeft - padRight);
    final chartH = math.max(1.0, size.height - padTop - padBottom);
    final totalKm = stage.totalDistanceKm > 0 ? stage.totalDistanceKm : 1.0;

    final minAlt = stage.minElevationM;
    final maxAlt = math.max(minAlt + 50.0, stage.maxElevationM);
    final altRange = maxAlt - minAlt;

    double xForKm(double km) => padLeft + (km / totalKm) * chartW;
    double yForAlt(double alt) =>
        padTop + chartH - ((alt - minAlt) / altRange) * chartH;

    // Linie siatki wysokościowej
    final gridPaint = Paint()
      ..color = const Color(0xFF2E3440).withValues(alpha: 0.65)
      ..strokeWidth = 0.8;
    for (var i = 0; i <= 2; i++) {
      final y = padTop + (chartH / 2) * i;
      canvas.drawLine(Offset(padLeft, y), Offset(padLeft + chartW, y), gridPaint);
    }

    final fillPath = Path();
    final linePath = Path();

    final firstSeg = segments.first;
    final startX = xForKm(firstSeg.startKm);
    final startY = yForAlt(firstSeg.startElevationM);
    fillPath.moveTo(startX, padTop + chartH);
    fillPath.lineTo(startX, startY);
    linePath.moveTo(startX, startY);

    for (final seg in segments) {
      final endX = xForKm(seg.endKm);
      final endY = yForAlt(seg.endElevationM);
      fillPath.lineTo(endX, endY);
      linePath.lineTo(endX, endY);
    }

    final lastX = xForKm(segments.last.endKm);
    fillPath.lineTo(lastX, padTop + chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryAccent.withValues(alpha: 0.45),
          AppColors.goldAccent.withValues(alpha: 0.08),
        ],
      ).createShader(Rect.fromLTWH(padLeft, padTop, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Kolorowane segmenty profilu wg nachylenia
    for (final seg in segments) {
      final p1 = Offset(xForKm(seg.startKm), yForAlt(seg.startElevationM));
      final p2 = Offset(xForKm(seg.endKm), yForAlt(seg.endElevationM));
      final grad = seg.gradientPercent;
      final Color segColor;
      if (grad >= 7.5) {
        segColor = AppColors.crimsonAlert;
      } else if (grad >= 4.0) {
        segColor = AppColors.amberWarning;
      } else if (grad >= 1.5) {
        segColor = AppColors.accentBlue;
      } else {
        segColor = AppColors.statusSuccess;
      }

      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = segColor
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round,
      );

      // Znaczniki premii górskich i lotnych
      if (seg.sprintOrKomClassification != SegmentClassification.none &&
          seg.sprintOrKomClassification != SegmentClassification.finishLine) {
        final isSprint =
            seg.sprintOrKomClassification == SegmentClassification.intermediateSprint;
        final badgeColor =
            isSprint ? AppColors.statusSuccess : AppColors.crimsonAlert;
        canvas.drawCircle(p2, 4.0, Paint()..color = badgeColor);
        canvas.drawCircle(
          p2,
          4.0,
          Paint()
            ..color = AppColors.textPrimary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }

    // Etykiety Start / Meta na osi dystansu
    _drawLabel(
      canvas,
      '0 km',
      Offset(padLeft, padTop + chartH + 5),
      alignRight: false,
    );
    _drawLabel(
      canvas,
      '${totalKm.toStringAsFixed(0)} km',
      Offset(padLeft + chartW, padTop + chartH + 5),
      alignRight: true,
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset pos, {
    required bool alignRight,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final dx = alignRight ? pos.dx - tp.width : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(covariant _StageLoadingElevationPainter oldDelegate) {
    return oldDelegate.stage != stage;
  }
}
