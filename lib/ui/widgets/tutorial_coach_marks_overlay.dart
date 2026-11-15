import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../state/game_settings_notifier.dart';

/// Strefy interfejsu wyścigowego i menedżerskiego wskazywane przez strzałki wektorowe samouczka.
enum TutorialTargetZone {
  /// Główny obszar peletonu i strugi aerodynamicznej (Drafting)
  pelotonViewport,

  /// Dolna lewa karta telemetrii kolarza (W', glikogen, żele, bidony)
  telemetryHud,

  /// Dolny pasek rozkazów taktycznych i tempa (Pociąg górski / Atak)
  tacticalControls,

  /// Prawy panel minimapy 2D i wyboru kamery / nawierzchni
  minimapAndSurface,

  /// Górny pasek HUD (dystans, profil, wiatr, mnożnik prędkości 1x-8x)
  topHudBar,

  /// Strefa kalendarza i planowania szczytu formy (TSB = CTL - ATL)
  calendarFormZone,
}

/// Pojedynczy kafelek metryki taktycznej w karcie samouczka.
class TutorialMetricChip {
  final String label;
  final String value;
  final Color color;

  const TutorialMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Definicja pojedynczego kroku interaktywnej akademii wyścigowej.
class TutorialAcademyStep {
  final int stepNumber;
  final String categoryBadge;
  final String title;
  final String subtitle;
  final String tacticalExplanation;
  final String proTip;
  final IconData icon;
  final Color accentColor;
  final TutorialTargetZone targetZone;
  final List<TutorialMetricChip> metrics;

  const TutorialAcademyStep({
    required this.stepNumber,
    required this.categoryBadge,
    required this.title,
    required this.subtitle,
    required this.tacticalExplanation,
    required this.proTip,
    required this.icon,
    required this.accentColor,
    required this.targetZone,
    required this.metrics,
  });
}

/// Lista 6 kroków trybu Interactive Race Academy.
const List<TutorialAcademyStep> kInteractiveRaceAcademySteps = [
  TutorialAcademyStep(
    stepNumber: 1,
    categoryBadge: 'KROK 1 / 6 • AERODYNAMIKA',
    title: 'Fizyka Draftingu i Wiatru',
    subtitle: 'Oszczędność energii w peletonie',
    tacticalExplanation:
        'Jazda na samym czele peletonu lub w pojedynkę wymaga 100% mocy, ponieważ kolarz przełamuje pełny opór powietrza. Schowanie lidera w środku grupy zmniejsza opór aerodynamiczny i oszczędza nawet do 45% watów na płaskim terenie.',
    proTip:
        'Utrzymuj lidera w głębi peletonu przez pierwsze 70% etapu. Na wietrze bocznym (echelony) przesuń go na czoło grupy, aby nie zostać na straconej pozycji.',
    icon: Icons.air_rounded,
    accentColor: AppColors.accentBlue,
    targetZone: TutorialTargetZone.pelotonViewport,
    metrics: [
      TutorialMetricChip(label: 'Czoło grupy', value: '100% mocy', color: AppColors.crimsonAlert),
      TutorialMetricChip(label: 'Środek peletonu', value: '55% (-45% W)', color: AppColors.statusSuccess),
      TutorialMetricChip(label: 'Klucz', value: 'Ochrona lidera', color: AppColors.goldAccent),
    ],
  ),
  TutorialAcademyStep(
    stepNumber: 2,
    categoryBadge: 'KROK 2 / 6 • FIZJOLOGIA & ŻYWIENIE',
    title: 'Zapas Beztlenowy W\' kontra Glikogen',
    subtitle: 'Zarządzanie energią i unikanie "bonka"',
    tacticalExplanation:
        'Czerwony pasek W\' (w kJ) to Twoja bateria beztlenowa na ataki i sprinty ponad próg FTP — regeneruje się, gdy jedziesz spokojniej. Żółty pasek Glikogenu (w gramach) to paliwo długodystansowe: jego wyczerpanie wywołuje "odcięcie prądu" (bonk) na finałowym podjeździe.',
    proTip:
        'Podawaj żel energetyczny regularnie, aby utrzymać podaż 90–120g węglowodanów/h na ciężkich etapach górskich, zanim glikogen spadnie poniżej krytycznego progu.',
    icon: Icons.bolt_rounded,
    accentColor: AppColors.amberWarning,
    targetZone: TutorialTargetZone.telemetryHud,
    metrics: [
      TutorialMetricChip(label: 'W\' (Czerwony)', value: 'kJ (ataki)', color: AppColors.crimsonAlert),
      TutorialMetricChip(label: 'Glikogen (Żółty)', value: 'g (paliwo)', color: AppColors.powerZone4),
      TutorialMetricChip(label: 'Podaż żeli', value: '90–120g / h', color: AppColors.goldAccent),
    ],
  ),
  TutorialAcademyStep(
    stepNumber: 3,
    categoryBadge: 'KROK 3 / 6 • TAKTYKA GÓRSKA',
    title: 'Pociąg Górski vs Samotny Atak',
    subtitle: 'Kontrola tempa przed skokiem lidera',
    tacticalExplanation:
        'Samotny atak z daleka szybko wypala zapas W\'. Zamiast tego ustaw 2–3 pomocników na czele grupy z zadanym tempem 5.8 W/kg, aby zmęczyć rywali i odciąć ich wsparcie, zanim lider wykona decydujący skok na ostatnich kilometrach.',
    proTip:
        'Kiedy ostatni pomocnik zakończy zmianę u podnóża finałowej ścianki, przełącz lidera na atak lub maksymalny wysiłek ponad próg.',
    icon: Icons.terrain_rounded,
    accentColor: AppColors.primaryAccent,
    targetZone: TutorialTargetZone.tacticalControls,
    metrics: [
      TutorialMetricChip(label: 'Tempo pociągu', value: '5.8 W/kg', color: AppColors.goldAccent),
      TutorialMetricChip(label: 'Cel pomocników', value: 'Selekcja grupy', color: AppColors.accentBlue),
      TutorialMetricChip(label: 'Finisz lidera', value: 'Atak z koła', color: AppColors.statusSuccess),
    ],
  ),
  TutorialAcademyStep(
    stepNumber: 4,
    categoryBadge: 'KROK 4 / 6 • SPRZĘT & NAWIERZCHNIA',
    title: 'Ciśnienie w oponach i Bruk',
    subtitle: 'Szerokość 28mm vs 32mm i opory toczenia (Crr)',
    tacticalExplanation:
        'Zbyt wysokie ciśnienie na bruku lub zniszczonym asfalcie powoduje podskakiwanie koła i wzrost strat toczenia (Crr) oraz ryzyka przebicia. Opony 32mm przy niższym ciśnieniu lepiej tłumią nierówności niż 28mm, redukując straty watów i liczbę defektów.',
    proTip:
        'Na klasyki brukowane (Paryż-Roubaix, Flandria) wybieraj szersze opony 32mm z niższym ciśnieniem BAR/PSI. Na gładki asfalt i czasówki pozostań przy 28mm.',
    icon: Icons.tire_repair_rounded,
    accentColor: AppColors.cyanAccent,
    targetZone: TutorialTargetZone.minimapAndSurface,
    metrics: [
      TutorialMetricChip(label: 'Asfalt / TT', value: '28mm (Aero)', color: AppColors.accentBlue),
      TutorialMetricChip(label: 'Bruk / Szuter', value: '32mm (-Crr)', color: AppColors.statusSuccess),
      TutorialMetricChip(label: 'Ryzyko przebicia', value: 'Zależne od BAR', color: AppColors.amberWarning),
    ],
  ),
  TutorialAcademyStep(
    stepNumber: 5,
    categoryBadge: 'KROK 5 / 6 • KALENDARZ & FORMA',
    title: 'Planowanie Szczytu Formy (TSB)',
    subtitle: 'Równanie TSB = CTL - ATL przed Grand Tourem',
    tacticalExplanation:
        'CTL to długoterminowa kondycja (Fitness), a ATL to bieżące zmęczenie (Fatigue). Równowaga formy TSB = CTL - ATL decyduje o świeżości kolarza: przed docelowym Grand Tourem zaplanuj zejście z obciążeń (tapering), aby TSB weszło w optymalne dodatnie okno.',
    proTip:
        'W kalendarzu sezonu ustaw obozy wysokogórskie na 4–6 tygodni przed celem, a ostatnie 10 dni przeznacz na regenerację, by osiągnąć szczyt TSB (+5 do +15).',
    icon: Icons.calendar_month_rounded,
    accentColor: AppColors.statusSuccess,
    targetZone: TutorialTargetZone.calendarFormZone,
    metrics: [
      TutorialMetricChip(label: 'Wzór formy', value: 'TSB = CTL - ATL', color: AppColors.goldAccent),
      TutorialMetricChip(label: 'Szczyt GT', value: '+5 do +15 TSB', color: AppColors.statusSuccess),
      TutorialMetricChip(label: 'Przetrenowanie', value: '< -25 TSB', color: AppColors.crimsonAlert),
    ],
  ),
  TutorialAcademyStep(
    stepNumber: 6,
    categoryBadge: 'KROK 6 / 6 • DOWODZENIE NA ŻYWO',
    title: 'Kontrola Tempa i Radio Wyścigowe',
    subtitle: 'Gotowość do startu i szybkie skróty',
    tacticalExplanation:
        'Górny pasek HUD pozwala przyspieszać czas symulacji (1x–8x), pauzować w kluczowych momentach i przewijać do następnego zdarzenia. Obserwuj komunikaty radia wyścigowego oraz profil wysokościowy, by wyprzedzać ruchy rywali.',
    proTip:
        'W każdej chwili możesz ponownie uruchomić Interactive Race Academy w ekranie Ustawień lub klikając ikonę pomocy w HUD wyścigu.',
    icon: Icons.headset_mic_rounded,
    accentColor: AppColors.goldAccent,
    targetZone: TutorialTargetZone.topHudBar,
    metrics: [
      TutorialMetricChip(label: 'Tempo czasu', value: '1x / 2x / 4x / 8x', color: AppColors.goldAccent),
      TutorialMetricChip(label: 'Skrót pauzy', value: 'Spacja', color: AppColors.accentBlue),
      TutorialMetricChip(label: 'Pominięcie', value: 'Esc / Ustawienia', color: AppColors.textSecondary),
    ],
  ),
];

/// Interaktywny system samouczka i podpowiedzi taktycznych w estetyce ciemnego szkła (#181B22)
/// ze złotą ramką (#D4AF37) i strzałkami wektorowymi wskazującymi elementy interfejsu.
class TutorialCoachMarksOverlay extends ConsumerStatefulWidget {
  /// Opcjonalna mapa kluczy widgetów docelowych, umożliwiająca precyzyjne wskazanie
  /// konkretnych elementów HUD w aktualnym drzewie widgetów.
  final Map<TutorialTargetZone, GlobalKey>? targetKeys;

  /// Wywołanie po ukończeniu wszystkich 6 kroków.
  final VoidCallback? onCompleted;

  /// Wywołanie po pominięciu samouczka w dowolnym momencie.
  final VoidCallback? onSkipped;

  /// Pozwala wymusić wyświetlenie nakładki (np. z ekranu Ustawień lub testów),
  /// niezależnie od flagi [GameSettings.hasCompletedRaceTutorial].
  final bool forceVisible;

  /// Początkowy indeks kroku (0..5).
  final int initialStepIndex;

  const TutorialCoachMarksOverlay({
    super.key,
    this.targetKeys,
    this.onCompleted,
    this.onSkipped,
    this.forceVisible = false,
    this.initialStepIndex = 0,
  });

  @override
  ConsumerState<TutorialCoachMarksOverlay> createState() =>
      _TutorialCoachMarksOverlayState();
}

class _TutorialCoachMarksOverlayState
    extends ConsumerState<TutorialCoachMarksOverlay>
    with SingleTickerProviderStateMixin {
  late int _currentStepIndex;
  late final AnimationController _pulseController;
  final FocusNode _keyboardFocusNode = FocusNode();

  // Stan interaktywnej symulacji w Kroku 4 (Ciśnienie i szerokość opon)
  bool _previewWideTire32mm = true;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStepIndex.clamp(
      0,
      kInteractiveRaceAcademySteps.length - 1,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  TutorialAcademyStep get _currentStep =>
      kInteractiveRaceAcademySteps[_currentStepIndex];

  void _goToStep(int index) {
    final clamped = index.clamp(0, kInteractiveRaceAcademySteps.length - 1);
    if (clamped == _currentStepIndex) return;
    setState(() => _currentStepIndex = clamped);
  }

  void _handleNextOrFinish() {
    if (_currentStepIndex < kInteractiveRaceAcademySteps.length - 1) {
      setState(() => _currentStepIndex++);
    } else {
      ref.read(gameSettingsProvider.notifier).completeRaceTutorial();
      widget.onCompleted?.call();
    }
  }

  void _handlePrevious() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
    }
  }

  void _handleSkip() {
    ref.read(gameSettingsProvider.notifier).skipRaceTutorial();
    widget.onSkipped?.call();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _handleSkip();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _handleNextOrFinish();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _handlePrevious();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Wyznacza prostokąt podświetlanego elementu HUD na podstawie [GlobalKey]
  /// lub responsywnego układu zastępczego, gdy klucz nie jest zamontowany.
  Rect _resolveTargetRect(Size viewportSize, TutorialTargetZone zone) {
    final key = widget.targetKeys?[zone];
    final targetContext = key?.currentContext;
    final overlayRenderObject = context.findRenderObject();

    if (targetContext != null && overlayRenderObject is RenderBox) {
      final targetBox = targetContext.findRenderObject();
      if (targetBox is RenderBox && targetBox.hasSize) {
        final topLeft = targetBox.localToGlobal(
          Offset.zero,
          ancestor: overlayRenderObject,
        );
        final rect = topLeft & targetBox.size;
        if (rect.width > 8 && rect.height > 8) {
          return rect.inflate(6);
        }
      }
    }

    // Responsywne kotwice zapasowe dla 390x844, 1024x768, 1600x900
    final w = viewportSize.width;
    final h = viewportSize.height;
    final isCompact = w < 640;

    switch (zone) {
      case TutorialTargetZone.pelotonViewport:
        return Rect.fromCenter(
          center: Offset(w * 0.5, h * (isCompact ? 0.30 : 0.44)),
          width: math.min(w * 0.55, 420),
          height: math.min(h * 0.24, 170),
        );
      case TutorialTargetZone.telemetryHud:
        return Rect.fromLTWH(
          16,
          h - (isCompact ? 180 : 210),
          math.min(w * 0.48, 340),
          isCompact ? 130 : 165,
        );
      case TutorialTargetZone.tacticalControls:
        return Rect.fromCenter(
          center: Offset(w * (isCompact ? 0.5 : 0.55), h - 78),
          width: math.min(w * 0.65, 420),
          height: 86,
        );
      case TutorialTargetZone.minimapAndSurface:
        return Rect.fromLTWH(
          math.max(16, w - math.min(w * 0.44, 376)),
          isCompact ? 86 : 124,
          math.min(w * 0.40, 350),
          isCompact ? 120 : 170,
        );
      case TutorialTargetZone.topHudBar:
        return Rect.fromLTWH(16, 12, math.max(180, w - 32), 62);
      case TutorialTargetZone.calendarFormZone:
        return Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.16),
          width: math.min(w * 0.62, 460),
          height: 76,
        );
    }
  }

  /// Wylicza optymalną pozycję karty samouczka, aby nie zasłaniała podświetlanego elementu
  /// i mieściła się bezpiecznie na ekranach 390x844, 1024x768 oraz 1600x900.
  Rect _resolveCardRect(Size viewportSize, Rect targetRect) {
    final w = viewportSize.width;
    final h = viewportSize.height;
    final isMobile = w < 640;
    final horizontalPadding = isMobile ? 14.0 : 28.0;
    final maxCardWidth = isMobile ? w - (horizontalPadding * 2) : math.min(470.0, w - 56.0);
    final estimatedCardHeight = isMobile
        ? math.min(h * 0.56, 450.0)
        : math.min(h * 0.62, 470.0);

    double left;
    double top;

    if (isMobile) {
      left = (w - maxCardWidth) / 2;
      final targetIsInUpperHalf = targetRect.center.dy < h * 0.45;
      top = targetIsInUpperHalf
          ? math.max(h - estimatedCardHeight - 18.0, targetRect.bottom + 24.0)
          : 18.0;
      top = top.clamp(14.0, math.max(14.0, h - estimatedCardHeight - 14.0));
    } else {
      // Na tablecie (1024x768) i desktopie (1600x900) ustawiamy kartę po przeciwnej stronie celu
      final targetOnLeft = targetRect.center.dx < w * 0.48;
      left = targetOnLeft
          ? math.min(w - maxCardWidth - 28.0, math.max(targetRect.right + 44.0, w * 0.50))
          : math.max(28.0, math.min(targetRect.left - maxCardWidth - 44.0, w * 0.12));

      final targetInUpper = targetRect.center.dy < h * 0.45;
      top = targetInUpper
          ? math.min(h - estimatedCardHeight - 28.0, math.max(96.0, h * 0.30))
          : math.max(28.0, (h - estimatedCardHeight) / 2);

      left = left.clamp(20.0, math.max(20.0, w - maxCardWidth - 20.0));
      top = top.clamp(20.0, math.max(20.0, h - estimatedCardHeight - 20.0));
    }

    return Rect.fromLTWH(left, top, maxCardWidth, estimatedCardHeight);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(gameSettingsProvider);
    final isVisible = widget.forceVisible ||
        (!settings.hasCompletedRaceTutorial && settings.showTutorialHints);

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          final isMobile = viewportSize.width < 640;
          final targetRect = _resolveTargetRect(viewportSize, _currentStep.targetZone);
          final cardRect = _resolveCardRect(viewportSize, targetRect);

          return Stack(
            children: [
              // Warstwa 1: Ciemny scrim z wycięciem spotlight i wektorową strzałką
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _CoachMarkSpotlightAndArrowPainter(
                        targetRect: targetRect,
                        cardRect: cardRect,
                        accentColor: AppColors.goldAccent,
                        pulseValue: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),

              // Warstwa 2: Szklana karta samouczka (#181B22 + złota ramka #D4AF37)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: cardRect.left,
                top: cardRect.top,
                width: cardRect.width,
                height: cardRect.height,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _buildGlassCoachCard(
                    key: ValueKey<int>(_currentStep.stepNumber),
                    step: _currentStep,
                    isMobile: isMobile,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassCoachCard({
    required Key key,
    required TutorialAcademyStep step,
    required bool isMobile,
  }) {
    final isFirstStep = _currentStepIndex == 0;
    final isLastStep = _currentStepIndex == kInteractiveRaceAcademySteps.length - 1;

    return ClipRRect(
      key: key,
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.goldAccent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Górna belka karty: odznaka kroku + przycisk "Pomiń"
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 18,
                  vertical: isMobile ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.72),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.goldAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.goldAccent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Icon(
                        step.icon,
                        size: 16,
                        color: AppColors.goldAccent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INTERACTIVE RACE ACADEMY',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: isMobile ? 9.5 : 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.goldAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            step.categoryBadge,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    _AcademyActionButton(
                      label: 'Pomiń',
                      icon: Icons.close_rounded,
                      variant: _AcademyButtonVariant.ghost,
                      compact: true,
                      onPressed: _handleSkip,
                    ),
                  ],
                ),
              ),

              // Treść przewijana (gwarantuje brak przepełnienia na 390x844)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 14 : 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.subtitle,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isMobile ? 12 : 12.5,
                          fontWeight: FontWeight.w600,
                          color: step.accentColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        step.tacticalExplanation,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: isMobile ? 12.5 : 13,
                          height: 1.45,
                          color: AppColors.textPrimary.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Mini-wizualizacja dedykowana do fizyki danego kroku
                      _buildStepInteractiveVisual(step, isMobile),
                      const SizedBox(height: 12),

                      // Kluczowe metryki liczbowe (tabularFigures)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: step.metrics.map((metric) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: metric.color.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  metric.label,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  metric.value,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: metric.color,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Wskazówka dyrektora sportowego
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.goldAccent.withValues(alpha: 0.32),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 16,
                              color: AppColors.goldAccent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                step.proTip,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  height: 1.4,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dolny pasek nawigacji: kropki kroków 1-6 + Poprzedni / Dalej
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 18,
                  vertical: isMobile ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight.withValues(alpha: 0.78),
                  border: const Border(
                    top: BorderSide(color: Color(0xFF2A2F3D), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Klikalne wskaźniki postępu kroków 1..6
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        kInteractiveRaceAcademySteps.length,
                        (index) => _StepIndicatorDot(
                          stepNumber: index + 1,
                          isActive: index == _currentStepIndex,
                          isCompleted: index < _currentStepIndex,
                          onTap: () => _goToStep(index),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _AcademyActionButton(
                            label: 'Poprzedni',
                            icon: Icons.arrow_back_rounded,
                            variant: _AcademyButtonVariant.secondary,
                            compact: isMobile,
                            onPressed: isFirstStep ? null : _handlePrevious,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _AcademyActionButton(
                            label: isLastStep ? 'Zakończ Akademię' : 'Dalej',
                            icon: isLastStep
                                ? Icons.check_circle_outline_rounded
                                : Icons.arrow_forward_rounded,
                            iconTrailing: !isLastStep,
                            variant: _AcademyButtonVariant.primaryGold,
                            compact: isMobile,
                            onPressed: _handleNextOrFinish,
                          ),
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
    );
  }

  Widget _buildStepInteractiveVisual(TutorialAcademyStep step, bool isMobile) {
    switch (step.stepNumber) {
      case 1:
        return _buildDraftingVisual();
      case 2:
        return _buildWPrimeVsGlycogenVisual();
      case 3:
        return _buildMountainTrainVisual();
      case 4:
        return _buildTirePressureCobblesVisual();
      case 5:
        return _buildTsbPeakFormVisual();
      case 6:
      default:
        return _buildRaceCommandVisual();
    }
  }

  Widget _buildDraftingVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildComparisonBar(
            label: 'Czoło grupy (pełny opór wiatru)',
            valueText: '100% W',
            fraction: 1.0,
            barColor: AppColors.crimsonAlert,
          ),
          const SizedBox(height: 8),
          _buildComparisonBar(
            label: 'Środek peletonu (efekt draftingu)',
            valueText: '55% W (-45%)',
            fraction: 0.55,
            barColor: AppColors.statusSuccess,
          ),
        ],
      ),
    );
  }

  Widget _buildWPrimeVsGlycogenVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildComparisonBar(
            label: 'W\' Zapas beztlenowy (czerwony pasek)',
            valueText: '18.5 / 22.0 kJ',
            fraction: 0.84,
            barColor: AppColors.crimsonAlert,
          ),
          const SizedBox(height: 8),
          _buildComparisonBar(
            label: 'Glikogen mięśniowy (żółty pasek)',
            valueText: '340 g (Żel: +30g)',
            fraction: 0.68,
            barColor: AppColors.powerZone4,
          ),
        ],
      ),
    );
  }

  Widget _buildMountainTrainVisual() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _buildTrainNode('Pomocnik 1', '5.8 W/kg', AppColors.accentBlue),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 16),
          _buildTrainNode('Pomocnik 2', '5.8 W/kg', AppColors.accentBlue),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 16),
          _buildTrainNode('Lider GC', 'Skok >6.4', AppColors.goldAccent),
        ],
      ),
    );
  }

  Widget _buildTrainNode(String role, String pace, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            Text(
              role,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              pace,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTirePressureCobblesVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _AcademyActionButton(
                  label: '28mm (6.2 BAR)',
                  variant: !_previewWideTire32mm
                      ? _AcademyButtonVariant.primaryGold
                      : _AcademyButtonVariant.secondary,
                  compact: true,
                  onPressed: () => setState(() => _previewWideTire32mm = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AcademyActionButton(
                  label: '32mm (4.6 BAR)',
                  variant: _previewWideTire32mm
                      ? _AcademyButtonVariant.primaryGold
                      : _AcademyButtonVariant.secondary,
                  compact: true,
                  onPressed: () => setState(() => _previewWideTire32mm = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _previewWideTire32mm
                ? 'Na bruku 32mm obniża straty toczenia Crr o ~18 W i drastycznie zmniejsza ryzyko przebicia ("snakebite").'
                : 'Na gładkim asfalcie 28mm zapewnia niższą powierzchnię czołową aero, lecz na bruku generuje wysokie Crr i ryzyko defektu.',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              height: 1.35,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTsbPeakFormVisual() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildComparisonBar(
              label: 'CTL (Kondycja) - ATL (Zmęczenie) = TSB (Świeżość)',
              valueText: 'CTL 98 - ATL 86 = +12 TSB',
              fraction: 0.82,
              barColor: AppColors.statusSuccess,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRaceCommandVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Wrap(
        spacing: 12,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Text(
            'Prędkość: 1x • 2x • 4x • 8x',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.goldAccent,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            'Auto-pauza na kluczowych momentach',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBar({
    required String label,
    required String valueText,
    required double fraction,
    required Color barColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              valueText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: barColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

/// Rysuje półprzezroczyste tło z wyciętym oknem na element docelowy, złotą pulsującą ramką
/// oraz krzywą strzałką wektorową łączącą kartę samouczka z elementem interfejsu.
class _CoachMarkSpotlightAndArrowPainter extends CustomPainter {
  final Rect targetRect;
  final Rect cardRect;
  final Color accentColor;
  final double pulseValue;

  const _CoachMarkSpotlightAndArrowPainter({
    required this.targetRect,
    required this.cardRect,
    required this.accentColor,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullScreenPath = Path()..addRect(Offset.zero & size);
    final spotlightRRect = RRect.fromRectAndRadius(
      targetRect,
      const Radius.circular(14),
    );
    final cutoutPath = Path()..addRRect(spotlightRRect);

    final scrimPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      cutoutPath,
    );

    // 1. Ciemny scrim z wycięciem
    final scrimPaint = Paint()
      ..color = AppColors.background.withValues(alpha: 0.72)
      ..style = PaintingStyle.fill;
    canvas.drawPath(scrimPath, scrimPaint);

    // 2. Pulsująca złota ramka wokół podświetlanego elementu
    final glowAlpha = 0.25 + (pulseValue * 0.25);
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: glowAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 + (pulseValue * 3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(spotlightRRect, glowPaint);

    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(spotlightRRect, borderPaint);

    // 3. Strzałka wektorowa z karty samouczka do podświetlanego elementu
    final start = _closestEdgePoint(cardRect, targetRect.center);
    final end = _closestEdgePoint(targetRect, cardRect.center);
    final distance = (end - start).distance;
    if (distance < 24) return;

    final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final norm = math.max(1.0, math.sqrt(dx * dx + dy * dy));
    // Lekkie wygięcie krzywej prostopadle do wektora
    final curveOffset = math.min(48.0, distance * 0.22);
    final controlPoint = Offset(
      mid.dx - (dy / norm) * curveOffset,
      mid.dy + (dx / norm) * curveOffset,
    );

    final arrowPath = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(controlPoint.dx, controlPoint.dy, end.dx, end.dy);

    final arrowPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(arrowPath, arrowPaint);

    // Grot strzałki zorientowany zgodnie ze styczną na końcu krzywej
    final tangentX = end.dx - controlPoint.dx;
    final tangentY = end.dy - controlPoint.dy;
    final angle = math.atan2(tangentY, tangentX);
    const arrowSize = 11.0;
    const spread = 0.45;

    final headPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - spread),
        end.dy - arrowSize * math.sin(angle - spread),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + spread),
        end.dy - arrowSize * math.sin(angle + spread),
      )
      ..close();

    final headPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(headPath, headPaint);

    // Złoty punkt zakotwiczenia na krawędzi karty
    canvas.drawCircle(start, 4.0, headPaint);
  }

  Offset _closestEdgePoint(Rect rect, Offset toward) {
    final cx = toward.dx.clamp(rect.left, rect.right);
    final cy = toward.dy.clamp(rect.top, rect.bottom);
    final dLeft = (toward.dx - rect.left).abs();
    final dRight = (toward.dx - rect.right).abs();
    final dTop = (toward.dy - rect.top).abs();
    final dBottom = (toward.dy - rect.bottom).abs();

    final minDist = math.min(math.min(dLeft, dRight), math.min(dTop, dBottom));
    if (minDist == dLeft) return Offset(rect.left, cy);
    if (minDist == dRight) return Offset(rect.right, cy);
    if (minDist == dTop) return Offset(cx, rect.top);
    return Offset(cx, rect.bottom);
  }

  @override
  bool shouldRepaint(covariant _CoachMarkSpotlightAndArrowPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.cardRect != cardRect ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.accentColor != accentColor;
  }
}

enum _AcademyButtonVariant { primaryGold, secondary, ghost }

/// Przycisk z pełną obsługą stanów hover, active (pressed), focus oraz disabled.
class _AcademyActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool iconTrailing;
  final _AcademyButtonVariant variant;
  final bool compact;
  final VoidCallback? onPressed;

  const _AcademyActionButton({
    required this.label,
    required this.variant,
    this.icon,
    this.iconTrailing = false,
    this.compact = false,
    this.onPressed,
  });

  @override
  State<_AcademyActionButton> createState() => _AcademyActionButtonState();
}

class _AcademyActionButtonState extends State<_AcademyActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    Color bgColor;
    Color fgColor;
    Color borderColor;

    switch (widget.variant) {
      case _AcademyButtonVariant.primaryGold:
        bgColor = isDisabled
            ? AppColors.goldAccent.withValues(alpha: 0.25)
            : _isPressed
                ? const Color(0xFFB5922A)
                : _isHovered
                    ? const Color(0xFFE3C152)
                    : AppColors.goldAccent;
        fgColor = isDisabled ? AppColors.textSecondary : AppColors.background;
        borderColor = _isFocused ? Colors.white : AppColors.goldAccent;
        break;
      case _AcademyButtonVariant.secondary:
        bgColor = isDisabled
            ? AppColors.surfaceLight.withValues(alpha: 0.35)
            : _isPressed
                ? AppColors.surfaceLight
                : _isHovered
                    ? AppColors.surfaceLight.withValues(alpha: 0.95)
                    : AppColors.surface;
        fgColor = isDisabled ? AppColors.textSecondary.withValues(alpha: 0.45) : AppColors.textPrimary;
        borderColor = _isFocused
            ? AppColors.goldAccent
            : _isHovered && !isDisabled
                ? AppColors.goldAccent.withValues(alpha: 0.6)
                : AppColors.cardBorder;
        break;
      case _AcademyButtonVariant.ghost:
        bgColor = _isPressed
            ? Colors.white12
            : _isHovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent;
        fgColor = _isHovered ? AppColors.textPrimary : AppColors.textSecondary;
        borderColor = _isFocused ? AppColors.goldAccent : Colors.transparent;
        break;
    }

    return FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      mouseCursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 10 : 14,
            vertical: widget.compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null && !widget.iconTrailing) ...[
                Icon(widget.icon, size: 15, color: fgColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: widget.compact ? 11.5 : 12.5,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ),
              if (widget.icon != null && widget.iconTrailing) ...[
                const SizedBox(width: 6),
                Icon(widget.icon, size: 15, color: fgColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Klikalna kropka wskaźnika kroku (1..6) ze stanem hover i focus.
class _StepIndicatorDot extends StatefulWidget {
  final int stepNumber;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback onTap;

  const _StepIndicatorDot({
    required this.stepNumber,
    required this.isActive,
    required this.isCompleted,
    required this.onTap,
  });

  @override
  State<_StepIndicatorDot> createState() => _StepIndicatorDotState();
}

class _StepIndicatorDotState extends State<_StepIndicatorDot> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isActive
        ? AppColors.goldAccent
        : widget.isCompleted
            ? AppColors.goldAccent.withValues(alpha: 0.45)
            : _isHovered
                ? AppColors.surfaceLight
                : Colors.white12;

    return Tooltip(
      message: 'Krok ${widget.stepNumber}',
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _isHovered = v),
        onShowFocusHighlight: (v) => setState(() => _isFocused = v),
        mouseCursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: widget.isActive ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(5),
              border: _isFocused
                  ? Border.all(color: Colors.white, width: 1.5)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
