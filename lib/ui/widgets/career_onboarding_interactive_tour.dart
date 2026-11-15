import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Identyfikatory 5 kluczowych obszarów podświetlanych przez samouczek kariery.
enum OnboardingHighlightTarget {
  /// Krok 1: Centrum dowodzenia — biuro menedżera, sponsorzy, skrzynka i forma TSB.
  managerOffice,

  /// Krok 2: Budowanie pociągu sprinterskiego/górskiego i hierarchii liderów.
  trainBuilder,

  /// Krok 3: Warsztat mechaników i kalkulator ciśnienia w oponach (BAR / PSI).
  tirePressureSetup,

  /// Krok 4: Sterowanie kolarzami w widoku 3D (rozkazy taktyczne, W/kg, kamery).
  race3dControls,

  /// Krok 5: Gotowość do etapu, odprawa przedstartowa i szybkie skróty.
  preRaceLaunch,
}

/// Pojedynczy kafelek parametru lub wskazówki w kroku samouczka.
class OnboardingTourMetric {
  final String label;
  final String value;
  final Color accentColor;

  const OnboardingTourMetric({
    required this.label,
    required this.value,
    required this.accentColor,
  });
}

/// Model pojedynczego kroku nieinwazyjnego samouczka dla nowego gracza.
class OnboardingTourStep {
  final int index;
  final OnboardingHighlightTarget target;
  final String categoryTag;
  final String title;
  final String subtitle;
  final String description;
  final String actionHint;
  final IconData icon;
  final Color accentColor;
  final List<OnboardingTourMetric> metrics;
  final Alignment defaultSpotlightAlignment;

  const OnboardingTourStep({
    required this.index,
    required this.target,
    required this.categoryTag,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.actionHint,
    required this.icon,
    required this.accentColor,
    required this.metrics,
    required this.defaultSpotlightAlignment,
  });
}

/// Domyślna lista 5 kroków samouczka kariery menedżera kolarskiego.
const List<OnboardingTourStep> kCareerOnboardingTourSteps = [
  OnboardingTourStep(
    index: 0,
    target: OnboardingHighlightTarget.managerOffice,
    categoryTag: 'BIURO MENEDŻERA',
    title: 'Centrum Dowodzenia HQ',
    subtitle: 'Sponsorzy, finanse, poczta i forma liderów',
    description:
        'Z tego miejsca zarządzasz całą drużyną WorldTour. Kontroluj zadowolenie sponsora tytularnego, sprawdzaj skrzynkę dyrektora sportowego oraz monitoruj współczynnik zmęczenia i świeżości (TSB) swoich liderów przed startem.',
    actionHint:
        'Obserwuj kalendarz i planuj szczyty formy (TSB > +5) na główne wyścigi sezonu.',
    icon: Icons.apartment_rounded,
    accentColor: AppColors.goldAccent,
    metrics: [
      OnboardingTourMetric(
        label: 'Cel TSB',
        value: '+5 .. +15',
        accentColor: AppColors.statusSuccess,
      ),
      OnboardingTourMetric(
        label: 'Sponsor',
        value: '3 cele / sezon',
        accentColor: AppColors.goldAccent,
      ),
      OnboardingTourMetric(
        label: 'Budżet',
        value: 'Kontrola płac',
        accentColor: AppColors.accentBlue,
      ),
    ],
    defaultSpotlightAlignment: Alignment(-0.55, -0.45),
  ),
  OnboardingTourStep(
    index: 1,
    target: OnboardingHighlightTarget.trainBuilder,
    categoryTag: 'TAKTYKA SKŁADU',
    title: 'Budowanie Pociągu i Ról',
    subtitle: 'Hierarchia lidera, rozprowadzających i pomocników',
    description:
        'Ustal klarowną strukturę przed każdym wyścigiem. Przydziel lidera GC lub sprintera oraz ustaw kolejność kolarzy w pociągu rozprowadzającym, aby chronić gwiazdę przed wiatrem i zaoszczędzić nawet 45% mocy.',
    actionHint:
        'W sekcji Składu i Odprawy przypisz role: Lider, Rozprowadzający i Domestique.',
    icon: Icons.linear_scale_rounded,
    accentColor: AppColors.primaryAccent,
    metrics: [
      OnboardingTourMetric(
        label: 'Drafting',
        value: '-35% .. -45% W',
        accentColor: AppColors.statusSuccess,
      ),
      OnboardingTourMetric(
        label: 'Pociąg',
        value: '3–4 kolarzy',
        accentColor: AppColors.goldAccent,
      ),
      OnboardingTourMetric(
        label: 'Ochrona',
        value: 'Lider w środku',
        accentColor: AppColors.accentBlue,
      ),
    ],
    defaultSpotlightAlignment: Alignment(-0.25, -0.15),
  ),
  OnboardingTourStep(
    index: 2,
    target: OnboardingHighlightTarget.tirePressureSetup,
    categoryTag: 'WARSZTAT & FIZYKA',
    title: 'Ciśnienie w Oponach i Nawierzchnia',
    subtitle: 'Optymalne BAR / PSI pod asfalt, deszcz i bruk',
    description:
        'Dobór ciśnienia bezpośrednio wpływa na opory toczenia (Crr) i ryzyko przebicia. Na gładkim asfalcie postaw na wyższe ciśnienie i 28mm, a na mokrych zjazdach lub sektorach bruku obniż BAR na szerszej oponie 32mm.',
    actionHint:
        'Przed etapem w panelu mechanika użyj suwaka BAR lub opcji "Optymalny Setup".',
    icon: Icons.tire_repair_rounded,
    accentColor: AppColors.cyanAccent,
    metrics: [
      OnboardingTourMetric(
        label: 'Asfalt 28mm',
        value: '5.4–6.2 BAR',
        accentColor: AppColors.accentBlue,
      ),
      OnboardingTourMetric(
        label: 'Bruk 32mm',
        value: '3.6–4.3 BAR',
        accentColor: AppColors.statusSuccess,
      ),
      OnboardingTourMetric(
        label: 'Deszcz',
        value: '-0.4 BAR',
        accentColor: AppColors.amberWarning,
      ),
    ],
    defaultSpotlightAlignment: Alignment(0.25, -0.10),
  ),
  OnboardingTourStep(
    index: 3,
    target: OnboardingHighlightTarget.race3dControls,
    categoryTag: 'WYŚCIG 3D NA ŻYWO',
    title: 'Sterowanie Kolarzami w 3D',
    subtitle: 'Suwak wysiłku, menu rozkazów i kamery wyścigowe',
    description:
        'Kliknij dowolnego kolarza na trasie 3D lub jego kartę w HUD, aby przejąć kontrolę. Reguluj intensywność jazdy (W/kg), wydawaj rozkazy ataku, podawania żeli oraz przełączaj kamery między helikopterem, moto i widokiem z kierownicy.',
    actionHint:
        'Prawy przycisk lub menu kołowe otwiera szybkie rozkazy: Atakuj, Na Kole, Żel.',
    icon: Icons.directions_bike_rounded,
    accentColor: AppColors.accentBlue,
    metrics: [
      OnboardingTourMetric(
        label: 'Wysiłek',
        value: '50% – 100%+',
        accentColor: AppColors.goldAccent,
      ),
      OnboardingTourMetric(
        label: 'Zapas W\'',
        value: 'Ataki ponad FTP',
        accentColor: AppColors.crimsonAlert,
      ),
      OnboardingTourMetric(
        label: 'Kamery',
        value: 'Heli / Moto / FPP',
        accentColor: AppColors.cyanAccent,
      ),
    ],
    defaultSpotlightAlignment: Alignment(0.0, 0.25),
  ),
  OnboardingTourStep(
    index: 4,
    target: OnboardingHighlightTarget.preRaceLaunch,
    categoryTag: 'START WYŚCIGU',
    title: 'Odprawa i Symulacja Etapu',
    subtitle: 'Przejście do startu KM 0.0 i skróty klawiszowe',
    description:
        'Gdy skład, pociąg i ciśnienie opon są gotowe, przejdź do najbliższego wyścigu z górnej karty HQ. Podczas etapu możesz przyspieszać czas (1x–8x), pauzować Spacją i reagować na ataki rywali w czasie rzeczywistym.',
    actionHint:
        'Możesz wrócić do samouczka w dowolnym momencie z poziomu Ustawień lub Pomocy.',
    icon: Icons.flag_rounded,
    accentColor: AppColors.statusSuccess,
    metrics: [
      OnboardingTourMetric(
        label: 'Pauza',
        value: 'Spacja',
        accentColor: AppColors.textPrimary,
      ),
      OnboardingTourMetric(
        label: 'Tempo',
        value: '1x / 2x / 4x / 8x',
        accentColor: AppColors.goldAccent,
      ),
      OnboardingTourMetric(
        label: 'Status',
        value: 'Gotowy do startu',
        accentColor: AppColors.statusSuccess,
      ),
    ],
    defaultSpotlightAlignment: Alignment(0.50, -0.40),
  ),
];

/// Stan kontrolera samouczka nowego gracza.
@immutable
class CareerOnboardingTourState {
  final bool isVisible;
  final int currentStepIndex;
  final bool isMinimized;
  final bool hasCompleted;
  final bool wasSkipped;

  const CareerOnboardingTourState({
    this.isVisible = true,
    this.currentStepIndex = 0,
    this.isMinimized = false,
    this.hasCompleted = false,
    this.wasSkipped = false,
  });

  CareerOnboardingTourState copyWith({
    bool? isVisible,
    int? currentStepIndex,
    bool? isMinimized,
    bool? hasCompleted,
    bool? wasSkipped,
  }) {
    return CareerOnboardingTourState(
      isVisible: isVisible ?? this.isVisible,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isMinimized: isMinimized ?? this.isMinimized,
      hasCompleted: hasCompleted ?? this.hasCompleted,
      wasSkipped: wasSkipped ?? this.wasSkipped,
    );
  }
}

/// Notifier zarządzający postępem i widocznością samouczka kariery.
class CareerOnboardingTourNotifier
    extends StateNotifier<CareerOnboardingTourState> {
  final int totalSteps;

  CareerOnboardingTourNotifier({
    this.totalSteps = 5,
    CareerOnboardingTourState? initialState,
  }) : super(initialState ?? const CareerOnboardingTourState());

  void startTour({int stepIndex = 0}) {
    final maxIdx = math.max(0, totalSteps - 1);
    final safeIndex = stepIndex.clamp(0, maxIdx).toInt();
    state = state.copyWith(
      isVisible: true,
      currentStepIndex: safeIndex,
      isMinimized: false,
      wasSkipped: false,
    );
  }

  void nextStep() {
    if (state.currentStepIndex >= totalSteps - 1) {
      completeTour();
      return;
    }
    state = state.copyWith(
      currentStepIndex: state.currentStepIndex + 1,
      isMinimized: false,
    );
  }

  void previousStep() {
    if (state.currentStepIndex <= 0) return;
    state = state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
      isMinimized: false,
    );
  }

  void goToStep(int index) {
    if (totalSteps <= 0) return;
    final clamped = index.clamp(0, totalSteps - 1);
    state = state.copyWith(
      currentStepIndex: clamped,
      isMinimized: false,
    );
  }

  void toggleMinimized() {
    state = state.copyWith(isMinimized: !state.isMinimized);
  }

  void skipTour() {
    state = state.copyWith(
      isVisible: false,
      isMinimized: false,
      wasSkipped: true,
    );
  }

  void completeTour() {
    state = state.copyWith(
      isVisible: false,
      isMinimized: false,
      hasCompleted: true,
    );
  }

  void resetTour() {
    state = const CareerOnboardingTourState();
  }
}

/// Globalny provider stanu samouczka kariery.
final careerOnboardingTourProvider = StateNotifierProvider<
    CareerOnboardingTourNotifier, CareerOnboardingTourState>((ref) {
  return CareerOnboardingTourNotifier(
    totalSteps: kCareerOnboardingTourSteps.length,
  );
});

/// Nieinwazyjny samouczek dla nowego gracza podświetlający w 5 krokach
/// najważniejsze elementy biura menedżera, budowania pociągu, ustawiania
/// ciśnienia w oponach oraz sterowania kolarzami w 3D.
class CareerOnboardingInteractiveTour extends StatefulWidget {
  /// Opcjonalny widżet tła, nad którym wyświetlana jest warstwa samouczka.
  final Widget? child;

  /// Lista kroków samouczka (domyślnie 5 kroków [kCareerOnboardingTourSteps]).
  final List<OnboardingTourStep> steps;

  /// Czy samouczek jest aktualnie widoczny.
  final bool isVisible;

  /// Początkowy krok (0..steps.length-1).
  final int initialStep;

  /// Opcjonalne klucze [GlobalKey] powiązane z elementami UI do precyzyjnego podświetlenia.
  final Map<OnboardingHighlightTarget, GlobalKey>? targetKeys;

  /// Wywołanie przy zmianie kroku.
  final ValueChanged<OnboardingTourStep>? onStepChanged;

  /// Wywołanie po kliknięciu "Pomiń" lub naciśnięciu Escape.
  final VoidCallback? onSkip;

  /// Wywołanie po ukończeniu ostatniego kroku.
  final VoidCallback? onComplete;

  /// Czy tło poza kartą samouczka ma przepuszczać kliknięcia (tryb nieinwazyjny).
  final bool passThroughPointerEvents;

  const CareerOnboardingInteractiveTour({
    super.key,
    this.child,
    this.steps = kCareerOnboardingTourSteps,
    this.isVisible = true,
    this.initialStep = 0,
    this.targetKeys,
    this.onStepChanged,
    this.onSkip,
    this.onComplete,
    this.passThroughPointerEvents = true,
  });

  @override
  State<CareerOnboardingInteractiveTour> createState() =>
      _CareerOnboardingInteractiveTourState();
}

class _CareerOnboardingInteractiveTourState
    extends State<CareerOnboardingInteractiveTour>
    with SingleTickerProviderStateMixin {
  late int _currentStep;
  bool _isMinimized = false;
  bool _isDismissed = false;
  late final AnimationController _pulseController;
  final FocusNode _keyboardFocusNode =
      FocusNode(debugLabel: 'CareerOnboardingTourFocus');
  final GlobalKey _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final maxIdx = math.max(0, widget.steps.length - 1);
    _currentStep = widget.initialStep.clamp(0, maxIdx);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CareerOnboardingInteractiveTour oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _isDismissed = false;
      _isMinimized = false;
    }
    if (widget.initialStep != oldWidget.initialStep) {
      final maxIdx = math.max(0, widget.steps.length - 1);
      _currentStep = widget.initialStep.clamp(0, maxIdx);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    if (widget.steps.isEmpty) return;
    final clamped = index.clamp(0, widget.steps.length - 1);
    if (clamped == _currentStep) return;
    setState(() {
      _currentStep = clamped;
      _isMinimized = false;
    });
    widget.onStepChanged?.call(widget.steps[_currentStep]);
  }

  void _handleNext() {
    if (widget.steps.isEmpty) return;
    if (_currentStep >= widget.steps.length - 1) {
      setState(() {
        _isDismissed = true;
      });
      widget.onComplete?.call();
      return;
    }
    _goToStep(_currentStep + 1);
  }

  void _handlePrevious() {
    if (_currentStep <= 0) return;
    _goToStep(_currentStep - 1);
  }

  void _handleSkip() {
    setState(() {
      _isDismissed = true;
    });
    widget.onSkip?.call();
  }

  void _toggleMinimized() {
    setState(() {
      _isMinimized = !_isMinimized;
    });
  }

  Rect? _resolveTargetRect(
    OnboardingTourStep step,
    Size viewportSize,
  ) {
    final key = widget.targetKeys?[step.target];
    if (key != null && key.currentContext != null) {
      final targetBox = key.currentContext!.findRenderObject() as RenderBox?;
      final stackBox =
          _stackKey.currentContext?.findRenderObject() as RenderBox?;
      if (targetBox != null &&
          targetBox.hasSize &&
          targetBox.attached &&
          stackBox != null &&
          stackBox.hasSize) {
        final topLeft =
            targetBox.localToGlobal(Offset.zero, ancestor: stackBox);
        return topLeft & targetBox.size;
      }
    }

    // Fallback proporcjonalny, gdy nie przekazano GlobalKey lub cel jest w innej zakładce.
    final isCompact = viewportSize.width < 600;
    final boxWidth = isCompact
        ? math.min(220.0, viewportSize.width * 0.58)
        : math.min(280.0, viewportSize.width * 0.28);
    final boxHeight = isCompact ? 82.0 : 108.0;

    final alignX = step.defaultSpotlightAlignment.x;
    final alignY = step.defaultSpotlightAlignment.y;
    final centerX = viewportSize.width * 0.5 +
        alignX * (viewportSize.width * 0.5 - boxWidth * 0.6);
    final centerY = viewportSize.height * 0.5 +
        alignY * (viewportSize.height * 0.5 - boxHeight * 0.8);

    return Rect.fromCenter(
      center: Offset(
        centerX.clamp(boxWidth * 0.5 + 12, viewportSize.width - boxWidth * 0.5 - 12),
        centerY.clamp(boxHeight * 0.5 + 16, viewportSize.height - boxHeight * 0.5 - 16),
      ),
      width: boxWidth,
      height: boxHeight,
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _handleSkip();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _handleNext();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _handlePrevious();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (!widget.isVisible || _isDismissed || widget.steps.isEmpty) {
      return child ?? const SizedBox.shrink();
    }

    final step = widget.steps[_currentStep];
    final totalSteps = widget.steps.length;

    return Focus(
      focusNode: _keyboardFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(
            constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width,
            constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : MediaQuery.sizeOf(context).height,
          );
          final targetRect = _resolveTargetRect(step, viewportSize);
          final isMobile = viewportSize.width < 600;
          final isTablet =
              viewportSize.width >= 600 && viewportSize.width < 1200;

          return Stack(
            key: _stackKey,
            clipBehavior: Clip.none,
            children: [
              if (child != null) child,

              // Nieinwazyjna warstwa podświetlenia celu (przepuszcza kliknięcia).
              if (!_isMinimized && targetRect != null)
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: widget.passThroughPointerEvents,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _NonInvasiveSpotlightPainter(
                            targetRect: targetRect,
                            accentColor: step.accentColor,
                            pulseValue: _pulseController.value,
                            stepLabel: 'KROK ${step.index + 1}/$totalSteps',
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Pływająca karta samouczka lub zwinięta pigułka w rogu ekranu.
              if (_isMinimized)
                _buildMinimizedPill(step, totalSteps, isMobile)
              else
                _buildTourCardPlacement(
                  context: context,
                  step: step,
                  totalSteps: totalSteps,
                  viewportSize: viewportSize,
                  targetRect: targetRect,
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMinimizedPill(
    OnboardingTourStep step,
    int totalSteps,
    bool isMobile,
  ) {
    return Positioned(
      right: isMobile ? 12 : 24,
      bottom: isMobile ? 16 : 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: step.accentColor.withValues(alpha: 0.7),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(step.icon, size: 18, color: step.accentColor),
              const SizedBox(width: 8),
              Text(
                'Samouczek ${step.index + 1}/$totalSteps',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 10),
              _TourInteractiveButton(
                label: 'Rozwiń',
                icon: Icons.open_in_full_rounded,
                variant: _TourButtonVariant.secondary,
                compact: true,
                onPressed: _toggleMinimized,
              ),
              const SizedBox(width: 6),
              _TourInteractiveButton(
                label: 'Pomiń',
                variant: _TourButtonVariant.ghost,
                compact: true,
                onPressed: _handleSkip,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTourCardPlacement({
    required BuildContext context,
    required OnboardingTourStep step,
    required int totalSteps,
    required Size viewportSize,
    required Rect? targetRect,
    required bool isMobile,
    required bool isTablet,
  }) {
    if (isMobile) {
      final maxCardHeight = math.max(240.0, viewportSize.height * 0.62);
      return Positioned(
        left: 12,
        right: 12,
        bottom: 14,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxCardHeight),
          child: _buildTourCard(
            step: step,
            totalSteps: totalSteps,
            isMobile: true,
          ),
        ),
      );
    }

    final cardWidth = isTablet ? 440.0 : 490.0;
    final placeOnLeft = targetRect != null &&
        targetRect.center.dx > viewportSize.width * 0.52;
    final placeOnTop = targetRect != null &&
        targetRect.center.dy > viewportSize.height * 0.58;
    final maxCardHeight = math.max(280.0, viewportSize.height - 48);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      left: placeOnLeft ? 24 : null,
      right: placeOnLeft ? null : 24,
      top: placeOnTop ? 24 : null,
      bottom: placeOnTop ? null : 24,
      width: math.min(cardWidth, viewportSize.width - 48),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxCardHeight),
        child: _buildTourCard(
          step: step,
          totalSteps: totalSteps,
          isMobile: false,
        ),
      ),
    );
  }

  Widget _buildTourCard({
    required OnboardingTourStep step,
    required int totalSteps,
    required bool isMobile,
  }) {
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == totalSteps - 1;

    return Material(
      color: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: step.accentColor.withValues(alpha: 0.14),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCardHeader(step, totalSteps, isMobile),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: Column(
                          key: ValueKey<int>(step.index),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTitleSection(step, isMobile),
                            const SizedBox(height: 10),
                            Text(
                              step.description,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: isMobile ? 12.5 : 13.5,
                                height: 1.48,
                                color: AppColors.textPrimary
                                    .withValues(alpha: 0.92),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildMetricsWrap(step),
                            const SizedBox(height: 12),
                            _buildActionHintBanner(step),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStepDots(totalSteps, step.accentColor),
                  const SizedBox(height: 12),
                  _buildFooterActions(
                    isFirst: isFirst,
                    isLast: isLast,
                    accentColor: step.accentColor,
                    isMobile: isMobile,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(
    OnboardingTourStep step,
    int totalSteps,
    bool isMobile,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: step.accentColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: step.accentColor.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
            child: Text(
              'KROK ${step.index + 1} / $totalSteps • ${step.categoryTag}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: isMobile ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: step.accentColor,
                letterSpacing: 0.3,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _TourIconActionButton(
          tooltip: 'Zwiń samouczek',
          icon: Icons.minimize_rounded,
          onPressed: _toggleMinimized,
        ),
        const SizedBox(width: 6),
        _TourInteractiveButton(
          label: 'Pomiń',
          variant: _TourButtonVariant.ghost,
          compact: true,
          onPressed: _handleSkip,
        ),
      ],
    );
  }

  Widget _buildTitleSection(OnboardingTourStep step, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: isMobile ? 38 : 42,
          height: isMobile ? 38 : 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: step.accentColor.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
          child: Icon(
            step.icon,
            color: step.accentColor,
            size: isMobile ? 20 : 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                step.subtitle,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isMobile ? 12 : 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsWrap(OnboardingTourStep step) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: step.metrics.map((metric) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                metric.value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: metric.accentColor,
                  letterSpacing: -0.2,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionHintBanner(OnboardingTourStep step) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: step.accentColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            size: 16,
            color: step.accentColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.actionHint,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDots(int totalSteps, Color accentColor) {
    return Row(
      children: [
        for (int i = 0; i < totalSteps; i++) ...[
          _StepDotButton(
            index: i,
            isActive: i == _currentStep,
            isCompleted: i < _currentStep,
            accentColor: accentColor,
            onTap: () => _goToStep(i),
          ),
          if (i < totalSteps - 1) const SizedBox(width: 6),
        ],
        const Spacer(),
        Text(
          '${((_currentStep + 1) / totalSteps * 100).round()}%',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildFooterActions({
    required bool isFirst,
    required bool isLast,
    required Color accentColor,
    required bool isMobile,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          _TourInteractiveButton(
            label: 'Wstecz',
            icon: Icons.arrow_back_rounded,
            variant: _TourButtonVariant.secondary,
            enabled: !isFirst,
            compact: isMobile,
            onPressed: _handlePrevious,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _TourInteractiveButton(
                label: 'Pomiń samouczek',
                variant: _TourButtonVariant.ghost,
                compact: isMobile,
                onPressed: _handleSkip,
              ),
              const SizedBox(width: 8),
              _TourInteractiveButton(
                label: isLast ? 'Zakończ' : 'Dalej',
                icon:
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                iconAfterLabel: true,
                variant: _TourButtonVariant.primary,
                accentColor: accentColor,
                compact: isMobile,
                onPressed: _handleNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TourButtonVariant { primary, secondary, ghost }

/// Przycisk samouczka z pełną obsługą stanów hover, active, focus i disabled.
class _TourInteractiveButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool iconAfterLabel;
  final _TourButtonVariant variant;
  final Color? accentColor;
  final bool enabled;
  final bool compact;
  final VoidCallback onPressed;

  const _TourInteractiveButton({
    required this.label,
    required this.variant,
    required this.onPressed,
    this.icon,
    this.iconAfterLabel = false,
    this.accentColor,
    this.enabled = true,
    this.compact = false,
  });

  @override
  State<_TourInteractiveButton> createState() => _TourInteractiveButtonState();
}

class _TourInteractiveButtonState extends State<_TourInteractiveButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primaryAccent;
    final enabled = widget.enabled;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    if (!enabled) {
      backgroundColor = AppColors.surfaceLight.withValues(alpha: 0.35);
      foregroundColor = AppColors.textSecondary.withValues(alpha: 0.4);
      borderColor = AppTheme.borderColor.withValues(alpha: 0.5);
    } else {
      switch (widget.variant) {
        case _TourButtonVariant.primary:
          backgroundColor = _isPressed
              ? accent.withValues(alpha: 0.85)
              : _isHovered
                  ? accent
                  : AppColors.primaryAccent;
          foregroundColor = AppColors.textPrimary;
          borderColor = _isFocused
              ? AppColors.goldAccent
              : accent.withValues(alpha: 0.8);
          break;
        case _TourButtonVariant.secondary:
          backgroundColor = _isPressed
              ? AppColors.surfaceLight
              : _isHovered
                  ? AppColors.surfaceLight.withValues(alpha: 0.95)
                  : AppColors.surfaceLight.withValues(alpha: 0.65);
          foregroundColor = AppColors.textPrimary;
          borderColor =
              _isFocused ? AppColors.goldAccent : AppTheme.borderColor;
          break;
        case _TourButtonVariant.ghost:
          backgroundColor = _isPressed
              ? AppColors.surfaceLight.withValues(alpha: 0.55)
              : _isHovered
                  ? AppColors.surfaceLight.withValues(alpha: 0.35)
                  : Colors.transparent;
          foregroundColor =
              _isHovered ? AppColors.textPrimary : AppColors.textSecondary;
          borderColor = _isFocused
              ? AppColors.goldAccent
              : Colors.transparent;
          break;
      }
    }

    final horizontalPadding = widget.compact ? 10.0 : 14.0;
    final verticalPadding = widget.compact ? 7.0 : 9.0;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedScale(
            scale: _isPressed && enabled ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.icon != null && !widget.iconAfterLabel) ...[
                    Icon(widget.icon, size: 15, color: foregroundColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.compact ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: foregroundColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (widget.icon != null && widget.iconAfterLabel) ...[
                    const SizedBox(width: 6),
                    Icon(widget.icon, size: 15, color: foregroundColor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kompaktowy przycisk ikony w nagłówku karty z pełnymi stanami hover/active/focus.
class _TourIconActionButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _TourIconActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_TourIconActionButton> createState() => _TourIconActionButtonState();
}

class _TourIconActionButtonState extends State<_TourIconActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _pressed
                    ? AppColors.surfaceLight
                    : _hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.75)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
                  width: 1.0,
                ),
              ),
              child: Icon(
                widget.icon,
                size: 16,
                color: _hovered
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interaktywna kropka postępu kroku samouczka.
class _StepDotButton extends StatefulWidget {
  final int index;
  final bool isActive;
  final bool isCompleted;
  final Color accentColor;
  final VoidCallback onTap;

  const _StepDotButton({
    required this.index,
    required this.isActive,
    required this.isCompleted,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_StepDotButton> createState() => _StepDotButtonState();
}

class _StepDotButtonState extends State<_StepDotButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? widget.accentColor
        : widget.isCompleted
            ? AppColors.goldAccent.withValues(alpha: 0.7)
            : _hovered
                ? AppColors.textSecondary
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: widget.isActive ? 26 : 10,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
              border: _focused
                  ? Border.all(color: AppColors.textPrimary, width: 1.2)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Painter rysujący nieinwazyjną ramkę podświetlenia (bez blokowania widoku).
class _NonInvasiveSpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final Color accentColor;
  final double pulseValue;
  final String stepLabel;

  const _NonInvasiveSpotlightPainter({
    required this.targetRect,
    required this.accentColor,
    required this.pulseValue,
    required this.stepLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inflated = targetRect.inflate(6 + pulseValue * 4);
    final rrect = RRect.fromRectAndRadius(inflated, const Radius.circular(16));

    // Subtelna poświata na obwodzie podświetlanego obszaru.
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.16 + 0.10 * (1 - pulseValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0;
    canvas.drawRRect(rrect, glowPaint);

    // Wyraźna cienka ramka akcentu.
    final borderPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(targetRect.inflate(3), const Radius.circular(14)),
      borderPaint,
    );

    // Etykieta numeru kroku nad podświetloną strefą.
    final textPainter = TextPainter(
      text: TextSpan(
        text: stepLabel,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeWidth = textPainter.width + 14;
    final badgeHeight = textPainter.height + 6;
    final badgeLeft = targetRect.left.clamp(8.0, size.width - badgeWidth - 8.0);
    final badgeTop = (targetRect.top - badgeHeight - 8)
        .clamp(8.0, size.height - badgeHeight - 8.0);
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
      const Radius.circular(6),
    );

    canvas.drawRRect(
      badgeRect,
      Paint()..color = AppColors.surface.withValues(alpha: 0.94),
    );
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = accentColor.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    textPainter.paint(canvas, Offset(badgeLeft + 7, badgeTop + 3));
  }

  @override
  bool shouldRepaint(covariant _NonInvasiveSpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.stepLabel != stepLabel;
  }
}
