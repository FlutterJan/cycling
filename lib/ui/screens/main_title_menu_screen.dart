import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database/custom_mod_importer_service.dart';
import '../../services/database/save_game_manager.dart';
import '../../state/career_controller.dart';
import 'jersey_and_bike_livery_studio_screen.dart';
import 'settings_and_mod_screen.dart';
import 'stage_editor_creator_screen.dart';

/// Główny ekran tytułowy klasy AAA gry Pro Peloton Manager.
///
/// Zawiera:
/// - Pełnoekranowe animowane tło alpejskiej serpentyny o zachodzie słońca
///   ([AnimatedPelotonBackdropPainter]) z paralaksą reagującą na ruch kursora.
/// - Szklany lewy panel nawigacyjny (`BackdropFilter`) z logotypem, wskaźnikiem
///   aktywnej bazy danych oraz statusem ostatniego zapisu kariery.
/// - Animowane przyciski menu z mikro-interakcjami, dźwiękiem kliknięcia
///   oraz pełnymi stanami `hover` / `active` / `disabled` / `focus`.
class MainTitleMenuScreen extends ConsumerStatefulWidget {
  const MainTitleMenuScreen({super.key});

  @override
  ConsumerState<MainTitleMenuScreen> createState() =>
      _MainTitleMenuScreenState();
}

class _MainTitleMenuScreenState extends ConsumerState<MainTitleMenuScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _backdropController;

  // Cel i aktualna pozycja paralaksy myszy w zakresie [-1.0, 1.0]
  Offset _targetParallax = Offset.zero;
  Offset _currentParallax = Offset.zero;

  List<SaveSlotInfo> _slots = List.generate(6, (i) => SaveSlotInfo.empty(i));
  SaveSlotInfo? _latestSaveSlot;
  String _activeDatabaseLabel = 'Default Fictional DB v1.0';
  bool _isCustomModActive = false;
  bool _isLoadingAction = false;
  String? _loadingMessage;

  @override
  void initState() {
    super.initState();
    _backdropController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _backdropController.addListener(_tickParallax);
    _loadInitialMetadata();
  }

  @override
  void dispose() {
    _backdropController.removeListener(_tickParallax);
    _backdropController.dispose();
    super.dispose();
  }

  void _tickParallax() {
    // Płynne tłumienie paralaksy (60/120 FPS)
    final dx = _currentParallax.dx + (_targetParallax.dx - _currentParallax.dx) * 0.08;
    final dy = _currentParallax.dy + (_targetParallax.dy - _currentParallax.dy) * 0.08;
    _currentParallax = Offset(dx, dy);
  }

  Future<void> _loadInitialMetadata() async {
    await Future.wait([
      _refreshSaveSlots(),
      _refreshDatabaseStatus(),
    ]);
  }

  Future<void> _refreshSaveSlots() async {
    try {
      final slots = await SaveGameManager.getAllSlots(includeAutoSave: true);
      final occupied = slots.where((s) => s.isOccupied).toList();
      occupied.sort((a, b) {
        final aTime = a.lastSavedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.lastSavedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      if (!mounted) return;
      setState(() {
        _slots = slots;
        _latestSaveSlot = occupied.isNotEmpty ? occupied.first : null;
      });
    } catch (_) {
      // Ignoruj błędy odczytu w środowisku bez systemu plików (np. testy)
    }
  }

  Future<void> _refreshDatabaseStatus() async {
    try {
      final modPackage = await CustomModImporterService.loadDefaultModPreset();
      if (!mounted) return;
      setState(() {
        if (modPackage != null) {
          _isCustomModActive = true;
          _activeDatabaseLabel =
              'Custom Real Name Pack Active (${modPackage.metadata.name} v${modPackage.metadata.version})';
        } else {
          _isCustomModActive = false;
          _activeDatabaseLabel = 'Default Fictional DB v1.0';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCustomModActive = false;
        _activeDatabaseLabel = 'Default Fictional DB v1.0';
      });
    }
  }

  void _playClickSound() {
    try {
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  Future<void> _handleContinueCareer() async {
    _playClickSound();
    final activeSave = ref.read(careerProvider).save;
    if (activeSave != null) {
      context.goToDashboard();
      return;
    }

    final slot = _latestSaveSlot;
    if (slot == null) return;
    await _loadSlotAndNavigate(slot.slotNumber);
  }

  Future<void> _loadSlotAndNavigate(int slotNumber) async {
    setState(() {
      _isLoadingAction = true;
      _loadingMessage = slotNumber == 0
          ? 'Wczytywanie automatycznego zapisu...'
          : 'Wczytywanie kariery ze Slotu #$slotNumber...';
    });

    final controller = ref.read(careerProvider.notifier);
    final bool success = slotNumber == 0
        ? await controller.loadAutoSave()
        : await controller.loadFromSlot(slotNumber);

    if (!mounted) return;
    setState(() {
      _isLoadingAction = false;
      _loadingMessage = null;
    });

    if (success) {
      context.goToDashboard();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.crimsonAlert,
          content: Text(
            'Nie udało się wczytać zapisu ze slotu #$slotNumber.',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
        ),
      );
    }
  }

  Future<void> _openLoadGameModal() async {
    _playClickSound();
    await _refreshSaveSlots().timeout(
      const Duration(milliseconds: 250),
      onTimeout: () {},
    );
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogCtx) => _LoadGameSlotsDialog(
        initialSlots: _slots,
        onLoadSlot: (slotNumber) async {
          Navigator.of(dialogCtx).pop();
          await _loadSlotAndNavigate(slotNumber);
        },
        onSlotsChanged: _refreshSaveSlots,
      ),
    );
  }

  Future<void> _openCreatorStudioChooser() async {
    _playClickSound();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogCtx) => _CreativeToolsModal(
        onOpenStageEditor: () {
          _playClickSound();
          Navigator.of(dialogCtx).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (routeCtx) => StageEditorCreatorScreen(
                onBack: () => Navigator.of(routeCtx).pop(),
              ),
            ),
          );
        },
        onOpenLiveryStudio: () {
          _playClickSound();
          Navigator.of(dialogCtx).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (routeCtx) => JerseyAndBikeLiveryStudioScreen(
                onBack: () => Navigator.of(routeCtx).pop(),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSettingsAndMods() async {
    _playClickSound();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsAndModScreen(),
      ),
    );
    if (mounted) {
      await _refreshDatabaseStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCareerSave = ref.watch(careerProvider).save;
    final bool hasContinuableSave =
        activeCareerSave != null || _latestSaveSlot != null;

    final String? continueTeamName = activeCareerSave?.playerTeam.name ??
        _latestSaveSlot?.playerTeamName;
    final DateTime? continueDate = activeCareerSave?.currentDate ??
        _latestSaveSlot?.currentDate;
    final String continueDateLabel = continueDate != null
        ? '${continueDate.day.toString().padLeft(2, '0')}.${continueDate.month.toString().padLeft(2, '0')}.${continueDate.year}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: MouseRegion(
        onHover: (event) {
          final size = MediaQuery.sizeOf(context);
          if (size.width <= 0 || size.height <= 0) return;
          final nx = ((event.position.dx / size.width) - 0.5) * 2.0;
          final ny = ((event.position.dy / size.height) - 0.5) * 2.0;
          _targetParallax = Offset(nx.clamp(-1.0, 1.0), ny.clamp(-1.0, 1.0));
        },
        onExit: (_) {
          _targetParallax = Offset.zero;
        },
        child: Stack(
          children: [
            // 1. Dynamiczne tło 3D/Canvas (60/120 FPS)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _backdropController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: AnimatedPelotonBackdropPainter(
                        progress: _backdropController.value,
                        parallax: _currentParallax,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
              ),
            ),

            // 2. Winieta poprawiająca czytelność lewego panelu
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppColors.background.withValues(alpha: 0.55),
                        Colors.transparent,
                        AppColors.background.withValues(alpha: 0.25),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Responsywny układ (390x844 / 1024x768 / 1600x900)
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isCompactMobile = constraints.maxWidth < 860;
                  final double panelWidth = constraints.maxWidth >= 1360
                      ? 448
                      : constraints.maxWidth >= 860
                          ? 396
                          : constraints.maxWidth - 24;

                  if (isCompactMobile) {
                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                        child: SizedBox(
                          width: panelWidth.clamp(280.0, 520.0),
                          child: _buildGlassNavigationPanel(
                            isCompact: true,
                            hasContinuableSave: hasContinuableSave,
                            continueTeamName: continueTeamName,
                            continueDateLabel: continueDateLabel,
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth >= 1360 ? 40 : 24,
                      vertical: 24,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: panelWidth,
                          child: _buildGlassNavigationPanel(
                            isCompact: false,
                            hasContinuableSave: hasContinuableSave,
                            continueTeamName: continueTeamName,
                            continueDateLabel: continueDateLabel,
                          ),
                        ),
                        const Spacer(),
                        // Prawy dolny znacznik sceny i silnika
                        Align(
                          alignment: Alignment.bottomRight,
                          child: _buildSceneTelemetryBadge(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 4. Nakładka ładowania podczas I/O zapisu
            if (_isLoadingAction)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.72),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: AppColors.goldAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _loadingMessage ?? 'Wczytywanie danych...',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
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
      ),
    );
  }

  Widget _buildGlassNavigationPanel({
    required bool isCompact,
    required bool hasContinuableSave,
    required String? continueTeamName,
    required String continueDateLabel,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withValues(alpha: 0.85),
                AppColors.background.withValues(alpha: 0.90),
              ],
            ),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Złota listwa akcentowa u góry panelu
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryAccent,
                      AppColors.goldAccent,
                      AppColors.primaryAccent,
                    ],
                  ),
                ),
              ),
              if (isCompact)
                _buildPanelInnerContent(
                  isCompact: true,
                  hasContinuableSave: hasContinuableSave,
                  continueTeamName: continueTeamName,
                  continueDateLabel: continueDateLabel,
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildPanelInnerContent(
                      isCompact: false,
                      hasContinuableSave: hasContinuableSave,
                      continueTeamName: continueTeamName,
                      continueDateLabel: continueDateLabel,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelInnerContent({
    required bool isCompact,
    required bool hasContinuableSave,
    required String? continueTeamName,
    required String continueDateLabel,
  }) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? 18 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo typograficzne
          _buildBrandHeader(isCompact: isCompact),
          const SizedBox(height: 14),

          // Wskaźnik aktywnej bazy danych
          _buildDatabaseBadge(),
          const SizedBox(height: 12),

          // Status ostatniego zapisu kariery
          _buildLastSaveStatusCard(
            hasContinuableSave: hasContinuableSave,
            teamName: continueTeamName,
            dateLabel: continueDateLabel,
          ),
          SizedBox(height: isCompact ? 16 : 20),

          // Przyciski głównego menu
          if (hasContinuableSave) ...[
            _TitleMenuButton(
              label: 'KONTYNUUJ KARIERĘ',
              subtitle:
                  '${continueTeamName ?? "Aktywna drużyna"}${continueDateLabel.isNotEmpty ? " • $continueDateLabel" : ""}',
              icon: Icons.play_arrow_rounded,
              isHighlighted: true,
              onPressed: _handleContinueCareer,
            ),
            const SizedBox(height: 10),
          ],

          _TitleMenuButton(
            label: 'NOWA KARIERA',
            subtitle: 'Wybierz zespół WorldTour lub utwórz własną ekipę',
            icon: Icons.add_circle_outline_rounded,
            onPressed: () {
              _playClickSound();
              context.goToNewCareer();
            },
          ),
          const SizedBox(height: 10),

          _TitleMenuButton(
            label: 'WCZYTAJ GRĘ',
            subtitle: 'Zarządzaj 5 slotami zapisu oraz importem i eksportem',
            icon: Icons.folder_open_rounded,
            onPressed: _openLoadGameModal,
          ),
          const SizedBox(height: 10),

          _TitleMenuButton(
            label: 'SZYBKI WYŚCIG (SANDBOX)',
            subtitle: 'Natychmiastowa symulacja 3D pojedynczego etapu',
            icon: Icons.speed_rounded,
            onPressed: () {
              _playClickSound();
              context.goToQuickRaceSandbox();
            },
          ),
          const SizedBox(height: 10),

          _TitleMenuButton(
            label: 'KREATOR TRAS I STUDIO MALOWANIA',
            subtitle: 'Edytor etapów oraz projektant koszulek i rowerów',
            icon: Icons.brush_rounded,
            onPressed: _openCreatorStudioChooser,
          ),
          const SizedBox(height: 10),

          _TitleMenuButton(
            label: 'BAZY DANYCH I USTAWIENIA',
            subtitle: 'Grafika 60/120 FPS, dźwięk oraz mody JSON',
            icon: Icons.tune_rounded,
            onPressed: _openSettingsAndMods,
          ),

          const SizedBox(height: 18),
          _buildPanelFooter(),
        ],
      ),
    );
  }

  Widget _buildBrandHeader({required bool isCompact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              child: const Text(
                'PRO CYCLING SIMULATION',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'PRO PELOTON\nMANAGER',
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textPrimary,
            fontSize: isCompact ? 26 : 31,
            fontWeight: FontWeight.w900,
            height: 1.02,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 24,
              height: 2,
              color: AppColors.goldAccent,
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'WORLD TOUR EDITION',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.goldAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.8,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDatabaseBadge() {
    final Color statusColor =
        _isCustomModActive ? AppColors.statusSuccess : AppColors.accentBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _activeDatabaseLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastSaveStatusCard({
    required bool hasContinuableSave,
    required String? teamName,
    required String dateLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasContinuableSave
              ? AppColors.goldAccent.withValues(alpha: 0.45)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasContinuableSave
                ? Icons.verified_rounded
                : Icons.history_toggle_off_rounded,
            size: 18,
            color: hasContinuableSave
                ? AppColors.goldAccent
                : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasContinuableSave
                      ? 'Ostatni zapis kariery'
                      : 'Status kariery',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasContinuableSave
                      ? '${teamName ?? "Zapisana drużyna"}${dateLabel.isNotEmpty ? " • $dateLabel" : ""}'
                      : 'Brak zapisu — rozpocznij nową karierę',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasContinuableSave
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 12,
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

  Widget _buildPanelFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '© 2026 Pro Peloton Manager',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ),
        SizedBox(width: 8),
        Text(
          'v1.0.0 AAA',
          style: TextStyle(
            color: AppColors.goldAccent,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSceneTelemetryBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.terrain_rounded,
                color: AppColors.goldAccent,
                size: 16,
              ),
              SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'COL DU GALIBIER • 2 642 M',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    'ALPEJSKI ZACHÓD SŁOŃCA • 60/120 FPS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
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

/// Animowany przycisk menu głównego z mikro-interakcjami:
/// rozszerzający się pasek akcentowy `#D4AF37`, płynne podświetlenie i stany
/// `hover` / `active` / `disabled` / `focus`.
class _TitleMenuButton extends StatefulWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isHighlighted;

  const _TitleMenuButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    this.onPressed,
    this.isHighlighted = false,
  });

  @override
  State<_TitleMenuButton> createState() => _TitleMenuButtonState();
}

class _TitleMenuButtonState extends State<_TitleMenuButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isDisabled => widget.onPressed == null;
  bool get _isActiveVisual => _isHovered || _isFocused;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    if (_isDisabled) {
      borderColor = AppTheme.borderColor.withValues(alpha: 0.45);
    } else if (_isActiveVisual) {
      borderColor = AppColors.goldAccent;
    } else if (widget.isHighlighted) {
      borderColor = AppColors.goldAccent.withValues(alpha: 0.55);
    } else {
      borderColor = AppTheme.borderColor;
    }

    final Color backgroundColor;
    if (_isDisabled) {
      backgroundColor = AppColors.surface.withValues(alpha: 0.35);
    } else if (_isPressed) {
      backgroundColor = AppColors.surfaceLight;
    } else if (_isActiveVisual) {
      backgroundColor = widget.isHighlighted
          ? AppColors.primaryAccent.withValues(alpha: 0.35)
          : AppColors.surfaceLight.withValues(alpha: 0.92);
    } else if (widget.isHighlighted) {
      backgroundColor = AppColors.primaryAccent.withValues(alpha: 0.22);
    } else {
      backgroundColor = AppColors.surface.withValues(alpha: 0.65);
    }

    return FocusableActionDetector(
      enabled: !_isDisabled,
      onShowHoverHighlight: (hovered) {
        if (_isHovered != hovered) setState(() => _isHovered = hovered);
      },
      onShowFocusHighlight: (focused) {
        if (_isFocused != focused) setState(() => _isFocused = focused);
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: _isDisabled
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: _isDisabled ? null : (_) => setState(() => _isPressed = true),
          onTapUp: _isDisabled
              ? null
              : (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed?.call();
                },
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(
              _isActiveVisual && !_isDisabled ? 4.0 : 0.0,
              _isPressed && !_isDisabled ? 1.0 : 0.0,
              0.0,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: _isActiveVisual && !_isDisabled
                  ? [
                      BoxShadow(
                        color: AppColors.goldAccent.withValues(alpha: 0.16),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pasek akcentowy #D4AF37 rozszerzający się przy najechaniu/focusie
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      width: _isDisabled
                          ? 3
                          : _isActiveVisual
                              ? 8
                              : widget.isHighlighted
                                  ? 5
                                  : 3,
                      decoration: BoxDecoration(
                        color: _isDisabled
                            ? AppColors.textSecondary.withValues(alpha: 0.3)
                            : (_isActiveVisual || widget.isHighlighted)
                                ? AppColors.goldAccent
                                : AppColors.primaryAccent,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              widget.icon,
                              size: 20,
                              color: _isDisabled
                                  ? AppColors.textSecondary.withValues(alpha: 0.45)
                                  : (_isActiveVisual || widget.isHighlighted)
                                      ? AppColors.goldAccent
                                      : AppColors.textPrimary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: _isDisabled
                                          ? AppColors.textSecondary
                                              .withValues(alpha: 0.5)
                                          : AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: _isDisabled
                                          ? AppColors.textSecondary
                                              .withValues(alpha: 0.4)
                                          : AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isActiveVisual && !_isDisabled ? 1.0 : 0.35,
                              child: Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: _isActiveVisual
                                    ? AppColors.goldAccent
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal wyboru jednego z 5 slotów zapisu z opcją importu i eksportu pliku.
class _LoadGameSlotsDialog extends StatefulWidget {
  final List<SaveSlotInfo> initialSlots;
  final Future<void> Function(int slotNumber) onLoadSlot;
  final Future<void> Function() onSlotsChanged;

  const _LoadGameSlotsDialog({
    required this.initialSlots,
    required this.onLoadSlot,
    required this.onSlotsChanged,
  });

  @override
  State<_LoadGameSlotsDialog> createState() => _LoadGameSlotsDialogState();
}

class _LoadGameSlotsDialogState extends State<_LoadGameSlotsDialog> {
  late List<SaveSlotInfo> _slots;
  bool _isBusy = false;
  String? _feedbackMessage;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _slots = List<SaveSlotInfo>.from(widget.initialSlots);
  }

  Future<void> _reloadSlots() async {
    final fresh = await SaveGameManager.getAllSlots(includeAutoSave: true);
    await widget.onSlotsChanged();
    if (!mounted) return;
    setState(() {
      _slots = fresh;
    });
  }

  Future<void> _handleExportSlot(int slotNumber) async {
    setState(() {
      _isBusy = true;
      _feedbackMessage = null;
    });
    try {
      final dir = await SaveGameManager.getSavesDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${dir.path}${Platform.pathSeparator}export_slot_${slotNumber}_$timestamp.ppm_save';
      final file = await SaveGameManager.exportSaveToFile(
        slotNumber: slotNumber,
        targetFilePath: filePath,
      );
      final jsonString =
          await SaveGameManager.exportSaveAsPortableJson(slotNumber: slotNumber);
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _feedbackIsError = false;
        _feedbackMessage =
            'Wyeksportowano Slot #$slotNumber do ${file.path} (JSON skopiowany do schowka).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _feedbackIsError = true;
        _feedbackMessage = 'Błąd eksportu: $e';
      });
    }
  }

  Future<void> _handleImportToSlot(int targetSlotNumber) async {
    final pathController = TextEditingController();
    final jsonController = TextEditingController();

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.borderColor),
        ),
        title: Text(
          'Importuj zapis do Slotu #$targetSlotNumber',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Podaj ścieżkę do pliku .ppm_save / .json lub wklej zawartość JSON zapisu:',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pathController,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Ścieżka do pliku (opcjonalnie)',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jsonController,
                  maxLines: 5,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Lub wklej JSON zapisu',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppTheme.borderColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Anuluj'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('Importuj'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      pathController.dispose();
      jsonController.dispose();
      return;
    }

    final filePath = pathController.text.trim();
    final rawJson = jsonController.text.trim();
    pathController.dispose();
    jsonController.dispose();

    if (filePath.isEmpty && rawJson.isEmpty) {
      setState(() {
        _feedbackIsError = true;
        _feedbackMessage = 'Wprowadź ścieżkę do pliku lub wklej kod JSON.';
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _feedbackMessage = null;
    });

    try {
      if (filePath.isNotEmpty) {
        await SaveGameManager.importSaveFromFile(
          file: File(filePath),
          targetSlotNumber: targetSlotNumber,
        );
      } else {
        await SaveGameManager.importPortableSave(
          dataString: rawJson,
          targetSlotNumber: targetSlotNumber,
        );
      }
      await _reloadSlots();
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _feedbackIsError = false;
        _feedbackMessage =
            'Pomyślnie zaimportowano zapis do Slotu #$targetSlotNumber.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _feedbackIsError = true;
        _feedbackMessage = 'Błąd importu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userSlots = List.generate(5, (i) {
      final slotNumber = i + 1;
      return _slots.firstWhere(
        (s) => s.slotNumber == slotNumber,
        orElse: () => SaveSlotInfo.empty(slotNumber),
      );
    });

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.save_rounded,
                        color: AppColors.goldAccent,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'WCZYTAJ GRĘ (SLOTY 1–5)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Wybierz zapis kariery do wczytania, wyeksportuj go do pliku .ppm_save lub zaimportuj z dysku.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              if (_feedbackMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (_feedbackIsError
                            ? AppColors.crimsonAlert
                            : AppColors.statusSuccess)
                        .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _feedbackIsError
                          ? AppColors.crimsonAlert
                          : AppColors.statusSuccess,
                    ),
                  ),
                  child: Text(
                    _feedbackMessage!,
                    style: TextStyle(
                      color: _feedbackIsError
                          ? AppColors.crimsonAlert
                          : AppColors.statusSuccess,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Flexible(
                child: _isBusy
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: AppColors.goldAccent,
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: userSlots.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final slot = userSlots[idx];
                          return _buildSlotTile(slot);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotTile(SaveSlotInfo slot) {
    final bool isEmpty = !slot.isOccupied;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEmpty ? AppColors.background : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty
              ? AppTheme.borderColor.withValues(alpha: 0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(
                    alpha: isEmpty ? 0.08 : 0.16,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.goldAccent.withValues(
                      alpha: isEmpty ? 0.25 : 0.55,
                    ),
                  ),
                ),
                child: Text(
                  'SLOT ${slot.slotNumber}',
                  style: TextStyle(
                    color: isEmpty
                        ? AppColors.textSecondary
                        : AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEmpty
                        ? 'Pusty slot zapisu'
                        : '${slot.saveName ?? "Kariera"} (${slot.playerTeamName ?? "Drużyna"})',
                    style: TextStyle(
                      color: isEmpty
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (!isEmpty)
                    Text(
                      'Data w grze: ${slot.formattedDate} • Zapis: ${slot.formattedLastSavedAt}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEmpty) ...[
                ElevatedButton(
                  onPressed: () => widget.onLoadSlot(slot.slotNumber),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: AppColors.textPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Wczytaj', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _handleExportSlot(slot.slotNumber),
                  icon: const Icon(Icons.upload_file_rounded, size: 15),
                  label: const Text('Eksportuj', style: TextStyle(fontSize: 11.5)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton.icon(
                onPressed: () => _handleImportToSlot(slot.slotNumber),
                icon: const Icon(Icons.download_rounded, size: 15),
                label: const Text('Importuj', style: TextStyle(fontSize: 11.5)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.goldAccent,
                  side: BorderSide(
                    color: AppColors.goldAccent.withValues(alpha: 0.5),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Modal wyboru między Kreatorem Tras a Studiem Malowania.
class _CreativeToolsModal extends StatelessWidget {
  final VoidCallback onOpenStageEditor;
  final VoidCallback onOpenLiveryStudio;

  const _CreativeToolsModal({
    required this.onOpenStageEditor,
    required this.onOpenLiveryStudio,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'KREATOR TRAS I STUDIO MALOWANIA',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Wybierz narzędzie projektowe, aby tworzyć własne etapy lub malowania drużynowe:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              _TitleMenuButton(
                label: 'KREATOR TRAS I ETAPÓW',
                subtitle: 'Projektuj profile górskie, bruki i premie KOM',
                icon: Icons.landscape_rounded,
                isHighlighted: true,
                onPressed: onOpenStageEditor,
              ),
              const SizedBox(height: 10),
              _TitleMenuButton(
                label: 'STUDIO MALOWANIA KOSZULEK I ROWERÓW',
                subtitle: 'Dostosuj barwy drużyny, mankiety i lakier ramy',
                icon: Icons.palette_rounded,
                onPressed: onOpenLiveryStudio,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dynamiczne tło 3D/Canvas (`AnimatedPelotonBackdropPainter`) renderujące
/// w 60/120 FPS scenę sylwetek kolarzy pokonujących alpejską serpentynę
/// o zachodzie słońca, z obracającymi się szprychami, smugami świateł
/// wozów technicznych oraz subtelną paralaksą kamery.
class AnimatedPelotonBackdropPainter extends CustomPainter {
  final double progress;
  final Offset parallax;

  const AnimatedPelotonBackdropPainter({
    required this.progress,
    required this.parallax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final double phase = progress * 2.0 * math.pi;
    final Offset camOffset = Offset(
      parallax.dx * 18.0 + math.sin(phase) * 5.0,
      parallax.dy * 10.0 + math.cos(phase * 0.5) * 3.0,
    );

    _drawSunsetSky(canvas, size, camOffset, phase);
    _drawAlpineMountains(canvas, size, camOffset);
    _drawSerpentineRoad(canvas, size, camOffset);
    _drawSupportVehicleLightTrails(canvas, size, camOffset, phase);
    _drawClimbingPeloton(canvas, size, camOffset, phase);
  }

  void _drawSunsetSky(
    Canvas canvas,
    Size size,
    Offset camOffset,
    double phase,
  ) {
    final Rect skyRect = Offset.zero & size;
    final Paint skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.background,
          Color(0xFF1A1523),
          AppColors.primaryAccent,
          AppColors.goldAccent,
        ],
        stops: [0.0, 0.36, 0.70, 0.96],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Złote słońce zachodzące nad alpejską przełęczą
    final Offset sunCenter = Offset(
      size.width * 0.68 - camOffset.dx * 0.25,
      size.height * 0.54 - camOffset.dy * 0.25,
    );
    final double sunRadius = math.min(size.width, size.height) * 0.34;
    final Paint sunGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.9),
          AppColors.primaryAccent.withValues(alpha: 0.45),
          Colors.transparent,
        ],
        stops: const [0.0, 0.42, 1.0],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: sunRadius));
    canvas.drawCircle(sunCenter, sunRadius, sunGlowPaint);

    // Subtelne gwiazdy na górnym granacie nieba
    final Paint starPaint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 28; i++) {
      final double rx = ((i * 73 + 19) % 100) / 100.0;
      final double ry = ((i * 41 + 7) % 34) / 100.0;
      final double twinkle = 0.25 + 0.55 * (0.5 + 0.5 * math.sin(phase * 2 + i));
      starPaint.color = AppColors.textPrimary.withValues(alpha: twinkle);
      canvas.drawCircle(
        Offset(
          rx * size.width - camOffset.dx * 0.1,
          ry * size.height - camOffset.dy * 0.1,
        ),
        (i % 3 == 0) ? 1.5 : 0.9,
        starPaint,
      );
    }
  }

  void _drawAlpineMountains(Canvas canvas, Size size, Offset camOffset) {
    // Warstwa 1: Odległe szczyty alpejskie
    final Path farPeaks = Path()
      ..moveTo(-40, size.height)
      ..lineTo(-40, size.height * 0.56)
      ..lineTo(size.width * 0.14 - camOffset.dx * 0.3, size.height * 0.42)
      ..lineTo(size.width * 0.28 - camOffset.dx * 0.3, size.height * 0.50)
      ..lineTo(size.width * 0.46 - camOffset.dx * 0.3, size.height * 0.34)
      ..lineTo(size.width * 0.61 - camOffset.dx * 0.3, size.height * 0.49)
      ..lineTo(size.width * 0.79 - camOffset.dx * 0.3, size.height * 0.37)
      ..lineTo(size.width * 0.94 - camOffset.dx * 0.3, size.height * 0.46)
      ..lineTo(size.width + 40, size.height * 0.41)
      ..lineTo(size.width + 40, size.height)
      ..close();

    canvas.drawPath(
      farPeaks,
      Paint()..color = const Color(0xFF1F1622).withValues(alpha: 0.85),
    );

    // Warstwa 2: Średni grzbiet górski z ciepłym rim-lightem
    final Path midRidge = Path()
      ..moveTo(-40, size.height)
      ..lineTo(-40, size.height * 0.66)
      ..lineTo(size.width * 0.18 - camOffset.dx * 0.55, size.height * 0.54)
      ..lineTo(size.width * 0.38 - camOffset.dx * 0.55, size.height * 0.62)
      ..lineTo(size.width * 0.58 - camOffset.dx * 0.55, size.height * 0.51)
      ..lineTo(size.width * 0.82 - camOffset.dx * 0.55, size.height * 0.59)
      ..lineTo(size.width + 40, size.height * 0.53)
      ..lineTo(size.width + 40, size.height)
      ..close();

    canvas.drawPath(
      midRidge,
      Paint()..color = const Color(0xFF14151D),
    );
  }

  void _drawSerpentineRoad(Canvas canvas, Size size, Offset camOffset) {
    final double ox = -camOffset.dx * 0.85;
    final double oy = -camOffset.dy * 0.7;

    // Górna wstęga serpentyny w oddali
    final Path upperSwitchback = Path()
      ..moveTo(size.width * 0.32 + ox * 0.6, size.height * 0.67 + oy * 0.6)
      ..quadraticBezierTo(
        size.width * 0.62 + ox * 0.6,
        size.height * 0.62 + oy * 0.6,
        size.width * 0.84 + ox * 0.6,
        size.height * 0.66 + oy * 0.6,
      );
    canvas.drawPath(
      upperSwitchback,
      Paint()
        ..color = const Color(0xFF222630)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );

    // Główny asfaltowy podjazd na pierwszym planie
    final Path roadSurface = Path()
      ..moveTo(-40, size.height * 0.94 + oy)
      ..cubicTo(
        size.width * 0.30 + ox,
        size.height * 0.86 + oy,
        size.width * 0.58 + ox,
        size.height * 0.72 + oy,
        size.width + 40,
        size.height * 0.75 + oy,
      )
      ..lineTo(size.width + 40, size.height + 20)
      ..lineTo(-40, size.height + 20)
      ..close();

    canvas.drawPath(
      roadSurface,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF222630),
            AppColors.background,
          ],
        ).createShader(Offset.zero & size),
    );

    // Złote odbicie zachodu słońca na krawędzi asfaltu
    final Path roadCrest = Path()
      ..moveTo(-40, size.height * 0.94 + oy)
      ..cubicTo(
        size.width * 0.30 + ox,
        size.height * 0.86 + oy,
        size.width * 0.58 + ox,
        size.height * 0.72 + oy,
        size.width + 40,
        size.height * 0.75 + oy,
      );
    canvas.drawPath(
      roadCrest,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  void _drawSupportVehicleLightTrails(
    Canvas canvas,
    Size size,
    Offset camOffset,
    double phase,
  ) {
    final double ox = -camOffset.dx * 0.65;
    final double oy = -camOffset.dy * 0.55;

    // Smugi czerwonych świateł tylnych wozu technicznego na wyższej serpentynie
    final double carT = (progress * 1.4) % 1.0;
    final Offset carPos = Offset(
      size.width * (0.42 + carT * 0.42) + ox,
      size.height * (0.65 - math.sin(carT * math.pi) * 0.03) + oy,
    );

    final Paint tailTrailPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primaryAccent.withValues(alpha: 0.85),
          AppColors.crimsonAlert,
        ],
      ).createShader(
        Rect.fromPoints(
          carPos - const Offset(85, -4),
          carPos,
        ),
      )
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(carPos - const Offset(85, -4), carPos, tailTrailPaint);

    // Stożek przednich reflektorów
    final Paint headlightPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.goldAccent.withValues(alpha: 0.55),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromPoints(
          carPos + const Offset(8, 0),
          carPos + const Offset(72, -3),
        ),
      )
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      carPos + const Offset(8, 0),
      carPos + const Offset(72, -3),
      headlightPaint,
    );

    // Sylwetka wozu technicznego
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: carPos, width: 22, height: 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF0A0C10),
    );
  }

  void _drawClimbingPeloton(
    Canvas canvas,
    Size size,
    Offset camOffset,
    double phase,
  ) {
    final double ox = -camOffset.dx * 0.9;
    final double oy = -camOffset.dy * 0.75;

    // 7 sylwetek kolarzy pokonujących podjazd w formacji
    const List<double> baseOffsets = [0.36, 0.44, 0.50, 0.56, 0.62, 0.69, 0.76];
    const List<double> scales = [0.68, 0.78, 0.85, 0.92, 1.0, 1.08, 1.16];

    for (int i = 0; i < baseOffsets.length; i++) {
      final double t = (baseOffsets[i] + progress * 0.16) % 0.88 + 0.10;
      final Offset pos = _sampleForegroundRoadPoint(size, t, ox, oy);
      final double scale = scales[i] * (size.width < 600 ? 0.78 : 1.0);
      final double wheelAngle = progress * 2.0 * math.pi * 16.0 + i * 0.9;
      final double cadenceBounce = math.sin(phase * 10.0 + i * 1.4) * 1.4;

      _drawCyclistSilhouette(
        canvas: canvas,
        groundPos: pos.translate(0, -2.0 * scale),
        scale: scale,
        wheelAngle: wheelAngle,
        cadenceBounce: cadenceBounce,
        isLeader: i == baseOffsets.length - 1,
      );
    }
  }

  Offset _sampleForegroundRoadPoint(
    Size size,
    double t,
    double ox,
    double oy,
  ) {
    final double x = (-40.0) * math.pow(1 - t, 3) +
        3 * (size.width * 0.30 + ox) * math.pow(1 - t, 2) * t +
        3 * (size.width * 0.58 + ox) * (1 - t) * t * t +
        (size.width + 40.0) * math.pow(t, 3);
    final double y = (size.height * 0.94 + oy) * math.pow(1 - t, 3) +
        3 * (size.height * 0.86 + oy) * math.pow(1 - t, 2) * t +
        3 * (size.height * 0.72 + oy) * (1 - t) * t * t +
        (size.height * 0.75 + oy) * math.pow(t, 3);
    return Offset(x, y);
  }

  void _drawCyclistSilhouette({
    required Canvas canvas,
    required Offset groundPos,
    required double scale,
    required double wheelAngle,
    required double cadenceBounce,
    required bool isLeader,
  }) {
    canvas.save();
    canvas.translate(groundPos.dx, groundPos.dy);
    canvas.rotate(-0.12); // Kąt podjazdu alpejskiego

    final double wheelR = 13.0 * scale;
    final Offset rearWheel = Offset(-18.0 * scale, -wheelR);
    final Offset frontWheel = Offset(18.0 * scale, -wheelR);

    final Paint silhouettePaint = Paint()
      ..color = const Color(0xFF0A0C10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    final Paint spokePaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.35)
      ..strokeWidth = 1.0 * scale;

    // Obręcze kół + obracające się szprychy
    for (final wheelCenter in [rearWheel, frontWheel]) {
      canvas.drawCircle(wheelCenter, wheelR, silhouettePaint);
      for (int s = 0; s < 6; s++) {
        final double a = wheelAngle + (s * math.pi / 3.0);
        canvas.drawLine(
          wheelCenter,
          wheelCenter + Offset(math.cos(a) * wheelR, math.sin(a) * wheelR),
          spokePaint,
        );
      }
    }

    // Rama roweru
    final Offset bb = Offset(-2.0 * scale, -wheelR + 2.0 * scale);
    final Offset seatCluster = Offset(-8.0 * scale, -wheelR - 14.0 * scale);
    final Offset headTube = Offset(10.0 * scale, -wheelR - 15.0 * scale);

    canvas.drawLine(rearWheel, bb, silhouettePaint);
    canvas.drawLine(rearWheel, seatCluster, silhouettePaint);
    canvas.drawLine(bb, seatCluster, silhouettePaint);
    canvas.drawLine(bb, headTube, silhouettePaint);
    canvas.drawLine(seatCluster, headTube, silhouettePaint);
    canvas.drawLine(headTube, frontWheel, silhouettePaint);

    // Sylwetka kolarza (korpus, ręce, kask, nogi)
    final Paint bodyPaint = Paint()
      ..color = const Color(0xFF0A0C10)
      ..style = PaintingStyle.fill;

    final Offset hip = Offset(-8.0 * scale, -wheelR - 19.0 * scale + cadenceBounce);
    final Offset shoulder = Offset(6.0 * scale, -wheelR - 30.0 * scale + cadenceBounce);
    final Offset head = Offset(11.0 * scale, -wheelR - 37.0 * scale + cadenceBounce);

    final Path torsoPath = Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(shoulder.dx, shoulder.dy)
      ..lineTo(shoulder.dx - 4.0 * scale, shoulder.dy + 5.0 * scale)
      ..lineTo(hip.dx + 4.0 * scale, hip.dy + 4.0 * scale)
      ..close();
    canvas.drawPath(torsoPath, bodyPaint);

    // Ręce na klamkomanetkach
    canvas.drawLine(
      shoulder,
      headTube + Offset(4.0 * scale, -4.0 * scale),
      silhouettePaint..strokeWidth = 3.0 * scale,
    );

    // Noga w ruchu korby
    final Offset pedal = bb +
        Offset(
          math.cos(wheelAngle * 0.35) * 5.0 * scale,
          math.sin(wheelAngle * 0.35) * 5.0 * scale,
        );
    canvas.drawLine(hip, pedal, silhouettePaint..strokeWidth = 3.2 * scale);

    // Kask z subtelnym złotym/czerwonym podświetleniem od zachodzącego słońca
    canvas.drawCircle(head, 5.2 * scale, bodyPaint);
    canvas.drawArc(
      Rect.fromCircle(center: head, radius: 5.5 * scale),
      -math.pi * 0.75,
      math.pi * 0.65,
      false,
      Paint()
        ..color = (isLeader ? AppColors.goldAccent : AppColors.primaryAccent)
            .withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AnimatedPelotonBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.parallax != parallax;
  }
}
