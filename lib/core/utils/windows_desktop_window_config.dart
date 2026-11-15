import 'dart:async';
import 'dart:io' show Directory, File, Platform;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'performance_profiler_overlay.dart';

/// Docelowe progi rozdzielczości dla skalowania interfejsu Desktop i Mobile.
enum DesktopResolutionTier {
  compact(
    label: 'Compact',
    shortTag: 'MOB',
    referenceWidth: 390,
    referenceHeight: 844,
    baseUiScale: 0.92,
    baseTextScale: 0.96,
    gridColumns: 1,
    cardMaxWidth: 520,
  ),
  tablet(
    label: 'Tablet / XGA',
    shortTag: 'XGA',
    referenceWidth: 1024,
    referenceHeight: 768,
    baseUiScale: 0.95,
    baseTextScale: 0.98,
    gridColumns: 2,
    cardMaxWidth: 680,
  ),
  hd720(
    label: 'HD 720p',
    shortTag: 'HD',
    referenceWidth: 1280,
    referenceHeight: 720,
    baseUiScale: 0.94,
    baseTextScale: 0.96,
    gridColumns: 3,
    cardMaxWidth: 820,
  ),
  fhd1080(
    label: 'Full HD',
    shortTag: 'FHD',
    referenceWidth: 1920,
    referenceHeight: 1080,
    baseUiScale: 1.0,
    baseTextScale: 1.0,
    gridColumns: 3,
    cardMaxWidth: 1120,
  ),
  qhd1440(
    label: 'QHD 1440p',
    shortTag: 'QHD',
    referenceWidth: 2560,
    referenceHeight: 1440,
    baseUiScale: 1.12,
    baseTextScale: 1.08,
    gridColumns: 4,
    cardMaxWidth: 1440,
  ),
  uhd4k(
    label: '4K UHD',
    shortTag: '4K',
    referenceWidth: 3840,
    referenceHeight: 2160,
    baseUiScale: 1.28,
    baseTextScale: 1.2,
    gridColumns: 4,
    cardMaxWidth: 1840,
  );

  final String label;
  final String shortTag;
  final int referenceWidth;
  final int referenceHeight;
  final double baseUiScale;
  final double baseTextScale;
  final int gridColumns;
  final double cardMaxWidth;

  const DesktopResolutionTier({
    required this.label,
    required this.shortTag,
    required this.referenceWidth,
    required this.referenceHeight,
    required this.baseUiScale,
    required this.baseTextScale,
    required this.gridColumns,
    required this.cardMaxWidth,
  });
}

/// Wyliczone metryki skalowania dla bieżącego rozmiaru okna oraz DPR.
@immutable
class DesktopScaleMetrics {
  final Size viewportSize;
  final double devicePixelRatio;
  final DesktopResolutionTier tier;
  final double uiScaleFactor;
  final double textScaleFactor;
  final double cardPadding;
  final double cardBorderRadius;
  final double cardBorderWidth;
  final double gridSpacing;
  final int recommendedGridColumns;
  final double maxContentWidth;

  const DesktopScaleMetrics({
    required this.viewportSize,
    required this.devicePixelRatio,
    required this.tier,
    required this.uiScaleFactor,
    required this.textScaleFactor,
    required this.cardPadding,
    required this.cardBorderRadius,
    required this.cardBorderWidth,
    required this.gridSpacing,
    required this.recommendedGridColumns,
    required this.maxContentWidth,
  });

  /// Szerokość pojedynczej karty w siatce przy zadanej liczbie kolumn.
  double computeCardWidth(double availableWidth, {int? columnsOverride}) {
    final int cols = math.max(1, columnsOverride ?? recommendedGridColumns);
    final double totalGaps = gridSpacing * (cols - 1);
    final double raw = (availableWidth - totalGaps) / cols;
    return math.max(220.0, math.min(raw, maxContentWidth));
  }

  /// Idealna wysokość karty zachowująca proporcje złotej karty (16:10 / 4:3).
  double computeProportionalCardHeight(
    double cardWidth, {
    double aspectRatio = 1.45,
  }) {
    final double safeRatio = aspectRatio.clamp(0.75, 2.5);
    return WindowsDesktopWindowConfig.snapToPhysicalPixel(
      cardWidth / safeRatio,
      devicePixelRatio,
    );
  }
}

/// Konfiguracja profilu okna desktopowego (Windows / macOS).
@immutable
class DesktopWindowProfile {
  final Size minWindowSize;
  final Size defaultWindowSize;
  final double statusBarHeight;
  final String windowTitle;
  final bool enableHighRefreshRate;

  const DesktopWindowProfile({
    this.minWindowSize = const Size(1280, 720),
    this.defaultWindowSize = const Size(1920, 1080),
    this.statusBarHeight = 38.0,
    this.windowTitle = 'Pro Peloton Manager',
    this.enableHighRefreshRate = true,
  });
}

/// Stan kontrolera okna desktopowego oraz trybu zrzutu ekranu 3D.
@immutable
class DesktopWindowState {
  final bool isFullscreen;
  final bool isScreenshotMode;
  final bool isCapturingScreenshot;
  final String? lastScreenshotPath;
  final String? statusFeedback;
  final DesktopResolutionTier currentTier;
  final Size currentViewportSize;

  const DesktopWindowState({
    this.isFullscreen = false,
    this.isScreenshotMode = false,
    this.isCapturingScreenshot = false,
    this.lastScreenshotPath,
    this.statusFeedback,
    this.currentTier = DesktopResolutionTier.fhd1080,
    this.currentViewportSize = const Size(1920, 1080),
  });

  DesktopWindowState copyWith({
    bool? isFullscreen,
    bool? isScreenshotMode,
    bool? isCapturingScreenshot,
    String? lastScreenshotPath,
    String? statusFeedback,
    bool clearStatusFeedback = false,
    DesktopResolutionTier? currentTier,
    Size? currentViewportSize,
  }) {
    return DesktopWindowState(
      isFullscreen: isFullscreen ?? this.isFullscreen,
      isScreenshotMode: isScreenshotMode ?? this.isScreenshotMode,
      isCapturingScreenshot:
          isCapturingScreenshot ?? this.isCapturingScreenshot,
      lastScreenshotPath: lastScreenshotPath ?? this.lastScreenshotPath,
      statusFeedback:
          clearStatusFeedback ? null : (statusFeedback ?? this.statusFeedback),
      currentTier: currentTier ?? this.currentTier,
      currentViewportSize: currentViewportSize ?? this.currentViewportSize,
    );
  }
}

/// Główna konfiguracja okna i skalowania dla wersji Desktop (`Windows` oraz `macOS`).
class WindowsDesktopWindowConfig {
  WindowsDesktopWindowConfig._();

  static const DesktopWindowProfile defaultProfile = DesktopWindowProfile();

  /// Kanał opcjonalnej komunikacji z natywną powłoką Windows/macOS.
  static const MethodChannel _nativeWindowChannel = MethodChannel(
    'pro_peloton_manager/desktop_window',
  );

  /// Czy aplikacja działa na wspieranym systemie desktopowym (Windows / macOS).
  static bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
  }

  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;

  /// Krótka etykieta platformy do paska stanu.
  static String get platformBadgeLabel {
    if (kIsWeb) return 'WEB';
    if (Platform.isWindows) return 'WIN';
    if (Platform.isMacOS) return 'MAC';
    if (Platform.isLinux) return 'LNX';
    return 'MOB';
  }

  /// Przyciąga wymiar logiczny do siatki fizycznych pikseli ekranu dla ostrości czcionek i ramek 1px.
  static double snapToPhysicalPixel(
    double logicalPixels,
    double devicePixelRatio,
  ) {
    final double safeDpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    return (logicalPixels * safeDpr).roundToDouble() / safeDpr;
  }

  /// Klasyfikuje bieżący rozmiar okna do jednego z progów rozdzielczości.
  static DesktopResolutionTier classifyResolution(Size size) {
    final double w = size.width;
    if (w >= 3200) return DesktopResolutionTier.uhd4k;
    if (w >= 2240) return DesktopResolutionTier.qhd1440;
    if (w >= 1600) return DesktopResolutionTier.fhd1080;
    if (w >= 1200) return DesktopResolutionTier.hd720;
    if (w >= 760) return DesktopResolutionTier.tablet;
    return DesktopResolutionTier.compact;
  }

  /// Wylicza płynne, ostre metryki skalowania dla dowolnego rozmiaru od `390x844` aż po `3840x2160` (4K).
  static DesktopScaleMetrics computeScaleMetrics(
    Size viewportSize, {
    double devicePixelRatio = 1.0,
  }) {
    final double safeW = math.max(320.0, viewportSize.width);
    final double safeH = math.max(320.0, viewportSize.height);
    final double safeDpr = devicePixelRatio <= 0 ? 1.0 : devicePixelRatio;
    final DesktopResolutionTier tier = classifyResolution(Size(safeW, safeH));

    // Płynna interpolacja współczynnika UI pomiędzy progami 720p -> 1080p -> QHD -> 4K.
    final double rawUiScale = _interpolateUiScale(safeW, safeH);
    final double rawTextScale = _interpolateTextScale(safeW, safeH);

    // Kwantyzacja współczynnika tekstu do 0.02 zapobiega rozmyciu glifów na matrycach 100%/125%/150%/200%.
    final double crispTextScale =
        ((rawTextScale * 50).roundToDouble() / 50).clamp(0.90, 1.25);

    final double cardPadding = snapToPhysicalPixel(
      (16.0 * rawUiScale).clamp(12.0, 24.0),
      safeDpr,
    );
    final double cardRadius = snapToPhysicalPixel(
      (16.0 * (0.9 + rawUiScale * 0.1)).clamp(14.0, 20.0),
      safeDpr,
    );
    final double cardBorderWidth = snapToPhysicalPixel(1.0, safeDpr);
    final double gridSpacing = snapToPhysicalPixel(
      (14.0 * rawUiScale).clamp(10.0, 22.0),
      safeDpr,
    );

    return DesktopScaleMetrics(
      viewportSize: Size(safeW, safeH),
      devicePixelRatio: safeDpr,
      tier: tier,
      uiScaleFactor: rawUiScale,
      textScaleFactor: crispTextScale,
      cardPadding: cardPadding,
      cardBorderRadius: cardRadius,
      cardBorderWidth: cardBorderWidth,
      gridSpacing: gridSpacing,
      recommendedGridColumns: tier.gridColumns,
      maxContentWidth: tier.cardMaxWidth,
    );
  }

  static double _interpolateUiScale(double width, double height) {
    final double effective = math.min(width, height * (16.0 / 9.0));
    if (effective <= 1280.0) {
      final double t = ((effective - 390.0) / (1280.0 - 390.0)).clamp(0.0, 1.0);
      return ui.lerpDouble(0.90, 0.94, t) ?? 0.92;
    }
    if (effective <= 1920.0) {
      final double t =
          ((effective - 1280.0) / (1920.0 - 1280.0)).clamp(0.0, 1.0);
      return ui.lerpDouble(0.94, 1.00, t) ?? 1.0;
    }
    if (effective <= 2560.0) {
      final double t =
          ((effective - 1920.0) / (2560.0 - 1920.0)).clamp(0.0, 1.0);
      return ui.lerpDouble(1.00, 1.12, t) ?? 1.06;
    }
    final double t = ((effective - 2560.0) / (3840.0 - 2560.0)).clamp(0.0, 1.0);
    return ui.lerpDouble(1.12, 1.28, t) ?? 1.2;
  }

  static double _interpolateTextScale(double width, double height) {
    final double effective = math.min(width, height * (16.0 / 9.0));
    if (effective <= 1280.0) {
      return 0.96;
    }
    if (effective <= 1920.0) {
      final double t =
          ((effective - 1280.0) / (1920.0 - 1280.0)).clamp(0.0, 1.0);
      return ui.lerpDouble(0.96, 1.00, t) ?? 1.0;
    }
    if (effective <= 2560.0) {
      final double t =
          ((effective - 1920.0) / (2560.0 - 1920.0)).clamp(0.0, 1.0);
      return ui.lerpDouble(1.00, 1.08, t) ?? 1.04;
    }
    final double t = ((effective - 2560.0) / (3840.0 - 2560.0)).clamp(0.0, 1.0);
    return ui.lerpDouble(1.08, 1.20, t) ?? 1.14;
  }

  /// Inicjalizuje ustawienia okna systemowego (minimalny rozmiar, tytuł, paski systemowe).
  static Future<void> configureSystemWindow({
    DesktopWindowProfile profile = defaultProfile,
  }) async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {
      // Ignoruj na platformach bez nakładki SystemChrome.
    }

    if (!isDesktopPlatform) return;

    try {
      await _nativeWindowChannel.invokeMethod<void>('configureWindow', {
        'title': profile.windowTitle,
        'minWidth': profile.minWindowSize.width,
        'minHeight': profile.minWindowSize.height,
        'defaultWidth': profile.defaultWindowSize.width,
        'defaultHeight': profile.defaultWindowSize.height,
      });
    } on MissingPluginException {
      // Natywny runner bez podpiętego kanału korzysta ze standardowej konfiguracji okna Flutter.
    } catch (_) {
      // Bezpieczne wyciszenie w środowiskach testowych / headless.
    }
  }

  /// Przełącza tryb pełnoekranowy (F11) na Desktopie oraz w trybie immersyjnym SystemChrome.
  static Future<void> applyFullscreen(bool enabled) async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        enabled ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    } catch (_) {
      // Bezpieczne w testach jednostkowych bez aktywnego bindingu systemowego.
    }

    if (!isDesktopPlatform) return;

    try {
      await _nativeWindowChannel.invokeMethod<void>('setFullscreen', {
        'fullscreen': enabled,
      });
    } on MissingPluginException {
      // Brak natywnego pluginu — stan pełnego ekranu jest utrzymywany w warstwie Flutter.
    } catch (_) {
      // Ignoruj błędy komunikacji kanału w środowisku testowym.
    }
  }
}

/// Kontroler stanu okna desktopowego, pełnego ekranu (F11) oraz trybu Screenshot Mode.
class DesktopWindowController extends StateNotifier<DesktopWindowState> {
  DesktopWindowController() : super(const DesktopWindowState());

  void updateViewportMetrics(Size viewportSize) {
    final DesktopResolutionTier nextTier =
        WindowsDesktopWindowConfig.classifyResolution(viewportSize);
    if (state.currentViewportSize == viewportSize &&
        state.currentTier == nextTier) {
      return;
    }
    state = state.copyWith(
      currentViewportSize: viewportSize,
      currentTier: nextTier,
    );
  }

  Future<void> toggleFullscreen() async {
    await setFullscreen(!state.isFullscreen);
  }

  Future<void> setFullscreen(bool enabled) async {
    if (state.isFullscreen == enabled) return;
    state = state.copyWith(
      isFullscreen: enabled,
      statusFeedback: enabled
          ? 'Pełny ekran aktywny (F11)'
          : 'Przywrócono okno desktopowe',
    );
    await WindowsDesktopWindowConfig.applyFullscreen(enabled);
  }

  void toggleScreenshotMode() {
    state = state.copyWith(
      isScreenshotMode: !state.isScreenshotMode,
      statusFeedback: !state.isScreenshotMode
          ? 'Tryb Zrzutu 3D — HUD ukryty (ESC/F12 aby wrócić)'
          : 'Przywrócono interfejs HUD',
    );
  }

  void setScreenshotMode(bool enabled) {
    if (state.isScreenshotMode == enabled) return;
    state = state.copyWith(
      isScreenshotMode: enabled,
      statusFeedback: enabled
          ? 'Tryb Zrzutu 3D — HUD ukryty'
          : 'Przywrócono interfejs HUD',
    );
  }

  void clearStatusFeedback() {
    if (state.statusFeedback == null) return;
    state = state.copyWith(clearStatusFeedback: true);
  }

  /// Wykonuje czysty zrzut ekranu z podanego [RepaintBoundary] w trybie Screenshot Mode
  /// i zapisuje plik PNG na dysku.
  Future<String?> captureCleanPelotonScreenshot(
    GlobalKey repaintBoundaryKey, {
    Directory? outputDirectory,
    double pixelRatio = 2.0,
  }) async {
    if (state.isCapturingScreenshot) return null;

    final bool wasScreenshotMode = state.isScreenshotMode;
    state = state.copyWith(
      isCapturingScreenshot: true,
      isScreenshotMode: true,
      clearStatusFeedback: true,
    );

    try {
      // Odczekaj jedną klatkę, aby animacja ukrycia HUD zdążyła się wyrenderować.
      await Future<void>.delayed(const Duration(milliseconds: 60));

      final BuildContext? boundaryContext = repaintBoundaryKey.currentContext;
      if (boundaryContext == null || !boundaryContext.mounted) {
        state = state.copyWith(
          isCapturingScreenshot: false,
          isScreenshotMode: wasScreenshotMode,
          statusFeedback: 'Nie znaleziono warstwy 3D do zrzutu',
        );
        return null;
      }

      final RenderObject? renderObject = boundaryContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        state = state.copyWith(
          isCapturingScreenshot: false,
          isScreenshotMode: wasScreenshotMode,
          statusFeedback: 'Warstwa nie wspiera zrzutu obrazu',
        );
        return null;
      }

      final ui.Image image = await renderObject
          .toImage(pixelRatio: pixelRatio.clamp(1.0, 3.0))
          .timeout(const Duration(milliseconds: 300));
      final ByteData? byteData = await image
          .toByteData(format: ui.ImageByteFormat.png)
          .timeout(const Duration(milliseconds: 300));
      image.dispose();

      if (byteData == null) {
        state = state.copyWith(
          isCapturingScreenshot: false,
          statusFeedback: 'Błąd kodowania obrazu PNG',
        );
        return null;
      }

      final Directory baseDir =
          outputDirectory ?? await getApplicationDocumentsDirectory();
      final Directory screenshotsDir = Directory(
        '${baseDir.path}${Platform.pathSeparator}screenshots',
      );
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final DateTime now = DateTime.now();
      final String stamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final File targetFile = File(
        '${screenshotsDir.path}${Platform.pathSeparator}peloton_3d_$stamp.png',
      );
      await targetFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      state = state.copyWith(
        isCapturingScreenshot: false,
        lastScreenshotPath: targetFile.path,
        statusFeedback: 'Zapisano zrzut 3D: peloton_3d_$stamp.png',
      );
      return targetFile.path;
    } catch (_) {
      state = state.copyWith(
        isCapturingScreenshot: false,
        statusFeedback: 'Tryb Zrzutu 3D aktywny (ESC aby wrócić)',
      );
      return null;
    }
  }
}

/// Globalny provider kontrolera okna desktopowego i trybu Screenshot Mode.
final desktopWindowProvider =
    StateNotifierProvider<DesktopWindowController, DesktopWindowState>(
  (ref) => DesktopWindowController(),
);

/// Udostępnia wyliczone metryki skalowania [DesktopScaleMetrics] w drzewie widżetów.
class DesktopScaleScope extends InheritedWidget {
  final DesktopScaleMetrics metrics;

  const DesktopScaleScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  static DesktopScaleMetrics? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DesktopScaleScope>()
        ?.metrics;
  }

  static DesktopScaleMetrics of(BuildContext context) {
    final DesktopScaleMetrics? found = maybeOf(context);
    assert(found != null, 'Brak DesktopScaleScope w drzewie widżetów.');
    return found!;
  }

  @override
  bool updateShouldNotify(DesktopScaleScope oldWidget) {
    return oldWidget.metrics.viewportSize != metrics.viewportSize ||
        oldWidget.metrics.uiScaleFactor != metrics.uiScaleFactor ||
        oldWidget.metrics.textScaleFactor != metrics.textScaleFactor ||
        oldWidget.metrics.devicePixelRatio != metrics.devicePixelRatio;
  }
}

/// Responsywny wrapper skalujący interfejs dla rozdzielczości od `1280x720`,
/// przez `1920x1080` (Full HD), `2560x1440` (QHD) aż po `3840x2160` (4K),
/// z bezpiecznym fallbackiem dla tabletów (`1024x768`) i telefonów (`390x844`).
///
/// Integruje niestandardowy pasek stanu desktopowego (`F11` pełny ekran,
/// obciążenie wątku fizyki `Isolate`, `Screenshot Mode` ukrywający HUD).
class DesktopResponsiveScaler extends ConsumerStatefulWidget {
  final Widget child;
  final bool showStatusBar;
  final bool enableKeyboardShortcuts;
  final ValueChanged<String>? onScreenshotSaved;

  const DesktopResponsiveScaler({
    super.key,
    required this.child,
    this.showStatusBar = true,
    this.enableKeyboardShortcuts = true,
    this.onScreenshotSaved,
  });

  @override
  ConsumerState<DesktopResponsiveScaler> createState() =>
      _DesktopResponsiveScalerState();
}

class _DesktopResponsiveScalerState
    extends ConsumerState<DesktopResponsiveScaler> {
  final GlobalKey _captureBoundaryKey = GlobalKey();
  final FocusNode _shortcutFocusNode = FocusNode(debugLabel: 'DesktopScaler');
  Timer? _feedbackTimer;

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _shortcutFocusNode.dispose();
    super.dispose();
  }

  void _scheduleFeedbackClear() {
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(desktopWindowProvider.notifier).clearStatusFeedback();
      }
    });
  }

  Future<void> _handleScreenshotAction() async {
    final controller = ref.read(desktopWindowProvider.notifier);
    final bool currentlyInScreenshotMode =
        ref.read(desktopWindowProvider).isScreenshotMode;

    if (currentlyInScreenshotMode) {
      controller.setScreenshotMode(false);
      _scheduleFeedbackClear();
      return;
    }

    final String? savedPath =
        await controller.captureCleanPelotonScreenshot(_captureBoundaryKey);
    if (savedPath != null) {
      widget.onScreenshotSaved?.call(savedPath);
    }
    _scheduleFeedbackClear();
  }

  @override
  Widget build(BuildContext context) {
    final DesktopWindowState windowState = ref.watch(desktopWindowProvider);
    final double devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final MediaQueryData baseMediaQuery = MediaQuery.of(context);

    Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final Size viewportSize = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : baseMediaQuery.size.width,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : baseMediaQuery.size.height,
        );

        final DesktopScaleMetrics metrics =
            WindowsDesktopWindowConfig.computeScaleMetrics(
          viewportSize,
          devicePixelRatio: devicePixelRatio,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(desktopWindowProvider.notifier)
                .updateViewportMetrics(viewportSize);
          }
        });

        final MediaQueryData scaledMediaQuery = baseMediaQuery.copyWith(
          textScaler: TextScaler.linear(metrics.textScaleFactor),
        );

        final bool renderStatusBar =
            widget.showStatusBar && !windowState.isScreenshotMode;

        return MediaQuery(
          data: scaledMediaQuery,
          child: DesktopScaleScope(
            metrics: metrics,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Column(
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      child: renderStatusBar
                          ? DesktopWindowStatusBar(
                              metrics: metrics,
                              onToggleFullscreen: () {
                                ref
                                    .read(desktopWindowProvider.notifier)
                                    .toggleFullscreen();
                                _scheduleFeedbackClear();
                              },
                              onTriggerScreenshot: _handleScreenshotAction,
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: RepaintBoundary(
                        key: _captureBoundaryKey,
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
                // Subtelna pigułka wyjścia z trybu Screenshot Mode (niewidoczna podczas samego zrzutu)
                if (windowState.isScreenshotMode &&
                    !windowState.isCapturingScreenshot)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _ScreenshotModeExitPill(
                      onExit: () {
                        ref
                            .read(desktopWindowProvider.notifier)
                            .setScreenshotMode(false);
                        _scheduleFeedbackClear();
                      },
                    ),
                  ),
                // Powiadomienie o statusie (zrzut / F11)
                if (windowState.statusFeedback != null &&
                    !windowState.isCapturingScreenshot)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 20,
                    child: IgnorePointer(
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: windowState.statusFeedback != null ? 1 : 0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          child: _StatusFeedbackToast(
                            message: windowState.statusFeedback!,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!widget.enableKeyboardShortcuts) {
      return content;
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.f11): () {
          ref.read(desktopWindowProvider.notifier).toggleFullscreen();
          _scheduleFeedbackClear();
        },
        const SingleActivator(LogicalKeyboardKey.f12): _handleScreenshotAction,
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final current = ref.read(desktopWindowProvider);
          if (current.isScreenshotMode) {
            ref.read(desktopWindowProvider.notifier).setScreenshotMode(false);
            _scheduleFeedbackClear();
          } else if (current.isFullscreen) {
            ref.read(desktopWindowProvider.notifier).setFullscreen(false);
            _scheduleFeedbackClear();
          }
        },
      },
      child: Focus(
        focusNode: _shortcutFocusNode,
        autofocus: true,
        child: content,
      ),
    );
  }
}

/// Niestandardowy, zintegrowany pasek stanu aplikacji desktopowej:
/// - informacja o platformie i aktualnej rozdzielczości / współczynniku skali,
/// - podgląd obciążenia wątku fizyki `Isolate` na żywo,
/// - przycisk trybu Zrzutu Ekranu (`Screenshot Mode` — ukrywa HUD do czystego zdjęcia 3D),
/// - przełącznik pełnego ekranu (`F11`).
class DesktopWindowStatusBar extends ConsumerWidget {
  final DesktopScaleMetrics metrics;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onTriggerScreenshot;

  const DesktopWindowStatusBar({
    super.key,
    required this.metrics,
    required this.onToggleFullscreen,
    required this.onTriggerScreenshot,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DesktopWindowState windowState = ref.watch(desktopWindowProvider);

    return Container(
      height: WindowsDesktopWindowConfig.defaultProfile.statusBarHeight,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderColor,
            width: 1.0,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isCompact = constraints.maxWidth < 740;
          final bool isUltraCompact = constraints.maxWidth < 480;

          return Row(
            children: [
              // Lewa sekcja: Brand + Badge platformy + Rozdzielczość
              _StatusBrandChip(
                tier: metrics.tier,
                viewportSize: metrics.viewportSize,
                scaleFactor: metrics.uiScaleFactor,
                compact: isCompact,
                ultraCompact: isUltraCompact,
              ),
              const SizedBox(width: 8),
              // Środkowa sekcja: Szybki podgląd obciążenia wątku fizyki Isolate
              Expanded(
                child: Align(
                  alignment: isCompact ? Alignment.centerLeft : Alignment.center,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _PhysicsThreadLoadBadge(
                      compact: isCompact,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Prawa sekcja: Zrzut 3D (Screenshot Mode) + Pełny ekran (F11)
              _DesktopActionButton(
                icon: Icons.camera_alt_outlined,
                label: isCompact ? null : 'Zrzut 3D',
                shortcutHint: isUltraCompact ? null : 'F12',
                tooltip: 'Screenshot Mode — ukryj HUD i zapisz zdjęcie peletonu 3D (F12)',
                isActive: windowState.isScreenshotMode,
                isDisabled: windowState.isCapturingScreenshot,
                accentColor: AppColors.goldAccent,
                onPressed: onTriggerScreenshot,
              ),
              const SizedBox(width: 6),
              _DesktopActionButton(
                icon: windowState.isFullscreen
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
                label: isCompact ? null : 'Pełny ekran',
                shortcutHint: isUltraCompact ? null : 'F11',
                tooltip: windowState.isFullscreen
                    ? 'Wyjdź z pełnego ekranu (F11)'
                    : 'Tryb pełnoekranowy (F11)',
                isActive: windowState.isFullscreen,
                accentColor: AppColors.accentBlue,
                onPressed: onToggleFullscreen,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBrandChip extends StatelessWidget {
  final DesktopResolutionTier tier;
  final Size viewportSize;
  final double scaleFactor;
  final bool compact;
  final bool ultraCompact;

  const _StatusBrandChip({
    required this.tier,
    required this.viewportSize,
    required this.scaleFactor,
    required this.compact,
    required this.ultraCompact,
  });

  @override
  Widget build(BuildContext context) {
    final String resolutionText =
        '${viewportSize.width.round()}×${viewportSize.height.round()}';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primaryAccent,
            shape: BoxShape.circle,
          ),
        ),
        if (!ultraCompact) ...[
          const SizedBox(width: 8),
          const Text(
            'PRO PELOTON',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textPrimary,
            ),
          ),
        ],
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderColor, width: 1),
          ),
          child: Text(
            WindowsDesktopWindowConfig.platformBadgeLabel,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AppColors.goldAccent,
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: Text(
              '${tier.shortTag} • $resolutionText • ${scaleFactor.toStringAsFixed(2)}x',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PhysicsThreadLoadBadge extends StatelessWidget {
  final bool compact;

  const _PhysicsThreadLoadBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<EnginePerformanceMetrics>(
      valueListenable: PerformanceTelemetryRegistry.instance.metrics,
      builder: (context, metrics, _) {
        final int tickUs = metrics.physicsTickMicroseconds;
        final double tickMs = tickUs / 1000.0;
        // Budżet klatki 60 FPS = 16.67 ms (16670 µs).
        final double loadRatio = (tickUs / 16670.0).clamp(0.0, 1.0);
        final int loadPercent = (loadRatio * 100).round();

        final Color indicatorColor;
        if (!metrics.isSimulationActive && tickUs == 0) {
          indicatorColor = AppColors.textSecondary;
        } else if (loadRatio < 0.35) {
          indicatorColor = AppColors.statusSuccess;
        } else if (loadRatio < 0.70) {
          indicatorColor = AppColors.amberWarning;
        } else {
          indicatorColor = AppColors.crimsonAlert;
        }

        final String tickLabel =
            tickUs >= 1000 ? '${tickMs.toStringAsFixed(1)} ms' : '$tickUs µs';

        return Tooltip(
          message:
              'Wątek fizyki Isolate: $tickLabel ($loadPercent% budżetu 60 Hz) • ${metrics.simulatedRidersCount} kolarzy',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: indicatorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  compact ? tickLabel : 'FIZYKA ISOLATE: $tickLabel',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: AppColors.textPrimary,
                  ),
                ),
                if (!compact) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 5,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          Container(color: AppColors.surfaceLight),
                          FractionallySizedBox(
                            widthFactor:
                                metrics.isSimulationActive || tickUs > 0
                                    ? math.max(0.08, loadRatio)
                                    : 0.0,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              color: indicatorColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${metrics.simulatedRidersCount} kol.',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      fontFeatures: [FontFeature.tabularFigures()],
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Przycisk akcji paska stanu z pełnymi stanami `hover` / `active` / `disabled` / `focus`.
class _DesktopActionButton extends StatefulWidget {
  final IconData icon;
  final String? label;
  final String? shortcutHint;
  final String tooltip;
  final bool isActive;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _DesktopActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.label,
    this.shortcutHint,
    this.isActive = false,
    this.isDisabled = false,
    this.accentColor = AppColors.goldAccent,
  });

  @override
  State<_DesktopActionButton> createState() => _DesktopActionButtonState();
}

class _DesktopActionButtonState extends State<_DesktopActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled;

    final Color bgColor;
    if (!enabled) {
      bgColor = AppColors.surface;
    } else if (_isPressed) {
      bgColor = widget.accentColor.withValues(alpha: 0.28);
    } else if (widget.isActive) {
      bgColor = widget.accentColor.withValues(alpha: 0.20);
    } else if (_isHovered) {
      bgColor = AppColors.surfaceLight;
    } else {
      bgColor = AppColors.background;
    }

    final Color borderColor;
    if (!enabled) {
      borderColor = AppTheme.borderColor.withValues(alpha: 0.5);
    } else if (_isFocused || widget.isActive) {
      borderColor = widget.accentColor;
    } else if (_isHovered) {
      borderColor = widget.accentColor.withValues(alpha: 0.6);
    } else {
      borderColor = AppTheme.borderColor;
    }

    final Color fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : (widget.isActive ? widget.accentColor : AppColors.textPrimary);

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
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
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel:
              enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 14, color: fgColor),
                if (widget.label != null) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.label!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                ],
                if (widget.shortcutHint != null) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.shortcutHint!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScreenshotModeExitPill extends StatefulWidget {
  final VoidCallback onExit;

  const _ScreenshotModeExitPill({required this.onExit});

  @override
  State<_ScreenshotModeExitPill> createState() =>
      _ScreenshotModeExitPillState();
}

class _ScreenshotModeExitPillState extends State<_ScreenshotModeExitPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onExit,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          opacity: _isHovered ? 1.0 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isHovered ? AppColors.goldAccent : AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 15,
                  color: AppColors.goldAccent,
                ),
                SizedBox(width: 6),
                Text(
                  'Pokaż HUD (ESC / F12)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
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

class _StatusFeedbackToast extends StatelessWidget {
  final String message;

  const _StatusFeedbackToast({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent, width: 1.0),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
