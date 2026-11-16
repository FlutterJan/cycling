import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';

/// Filtry kolorystyczne dostępne w Trybie Fotograficznym 3D.
enum PhotoColorFilterPreset {
  natural(
    id: 'natural',
    label: 'Naturalny',
    shortLabel: 'Natural',
    subtitle: 'Neutralna kolorystyka transmisji wyścigowej',
    accentColor: AppColors.accentBlue,
  ),
  classicBw1970(
    id: 'classic_bw_1970',
    label: 'Klasyczny Czarno-Biały 1970',
    shortLabel: 'B&W 1970',
    subtitle: 'Srebrowy film reporterski o wysokim kontraście',
    accentColor: AppColors.textPrimary,
  ),
  goldenHour(
    id: 'golden_hour',
    label: 'Złota Godzina',
    shortLabel: 'Złota Godzina',
    subtitle: 'Ciepłe światło alpejskiego zachodu słońca',
    accentColor: AppColors.goldAccent,
  ),
  hdrContrast(
    id: 'hdr_contrast',
    label: 'Kontrast HDR',
    shortLabel: 'HDR',
    subtitle: 'Głębokie cienie, mikro-kontrast i nasycenie',
    accentColor: AppColors.primaryAccent,
  );

  final String id;
  final String label;
  final String shortLabel;
  final String subtitle;
  final Color accentColor;

  const PhotoColorFilterPreset({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.subtitle,
    required this.accentColor,
  });

  /// Buduje macierz [ColorFilter] z uwzględnieniem intensywności [intensity] (0.0–1.0).
  ColorFilter? buildColorFilter({double intensity = 1.0}) {
    final t = intensity.clamp(0.0, 1.0);
    if (this == PhotoColorFilterPreset.natural || t <= 0.001) {
      return null;
    }

    const identity = <double>[
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    final List<double> target;
    switch (this) {
      case PhotoColorFilterPreset.natural:
        return null;
      case PhotoColorFilterPreset.classicBw1970:
        // Klasyczny film czarno-biały lat 70. z lekkim kontrastem srebrowym i ciepłą nutą.
        target = const <double>[
          0.36, 0.68, 0.13, 0, -18,
          0.35, 0.67, 0.13, 0, -19,
          0.32, 0.62, 0.12, 0, -21,
          0, 0, 0, 1, 0,
        ];
      case PhotoColorFilterPreset.goldenHour:
        // Ciepłe światło złotej godziny: wzmocnienie czerwieni/złota, wygaszenie chłodnego błękitu.
        target = const <double>[
          1.18, 0.06, -0.02, 0, 12,
          0.04, 1.05, 0.00, 0, 4,
          -0.04, 0.02, 0.80, 0, -10,
          0, 0, 0, 1, 0,
        ];
      case PhotoColorFilterPreset.hdrContrast:
        // Kontrast HDR: wyraźny skok kontrastu i nasycenia barw.
        target = const <double>[
          1.34, -0.10, -0.06, 0, -20,
          -0.08, 1.32, -0.06, 0, -20,
          -0.06, -0.08, 1.36, 0, -20,
          0, 0, 0, 1, 0,
        ];
    }

    final blended = List<double>.generate(
      20,
      (i) => identity[i] + (target[i] - identity[i]) * t,
      growable: false,
    );
    return ColorFilter.matrix(blended);
  }
}

/// Pozycja i orientacja swobodnej kamery 3D (Free Fly Cam).
@immutable
class PhotoCamera3dPose {
  final double positionX;
  final double positionY;
  final double positionZ;
  final double yawDegrees;
  final double pitchDegrees;
  final double rollDegrees;
  final double moveSpeedMetersPerSec;

  const PhotoCamera3dPose({
    this.positionX = 3.2,
    this.positionY = 2.1,
    this.positionZ = -7.5,
    this.yawDegrees = -18.0,
    this.pitchDegrees = -8.0,
    this.rollDegrees = 0.0,
    this.moveSpeedMetersPerSec = 8.0,
  });

  PhotoCamera3dPose copyWith({
    double? positionX,
    double? positionY,
    double? positionZ,
    double? yawDegrees,
    double? pitchDegrees,
    double? rollDegrees,
    double? moveSpeedMetersPerSec,
  }) {
    return PhotoCamera3dPose(
      positionX: (positionX ?? this.positionX).clamp(-150.0, 150.0),
      positionY: (positionY ?? this.positionY).clamp(0.35, 85.0),
      positionZ: (positionZ ?? this.positionZ).clamp(-200.0, 200.0),
      yawDegrees: _normalizeAngle(yawDegrees ?? this.yawDegrees),
      pitchDegrees: (pitchDegrees ?? this.pitchDegrees).clamp(-75.0, 75.0),
      rollDegrees: (rollDegrees ?? this.rollDegrees).clamp(-30.0, 30.0),
      moveSpeedMetersPerSec:
          (moveSpeedMetersPerSec ?? this.moveSpeedMetersPerSec).clamp(2.0, 30.0),
    );
  }

  /// Przesuwa kamerę w jej lokalnym układzie odniesienia (przód/prawo/góra).
  PhotoCamera3dPose movedLocal({
    double forward = 0.0,
    double right = 0.0,
    double up = 0.0,
  }) {
    final yawRad = yawDegrees * math.pi / 180.0;
    final forwardX = math.sin(yawRad);
    final forwardZ = math.cos(yawRad);
    final rightX = math.cos(yawRad);
    final rightZ = -math.sin(yawRad);

    return copyWith(
      positionX: positionX + forwardX * forward + rightX * right,
      positionY: positionY + up,
      positionZ: positionZ + forwardZ * forward + rightZ * right,
    );
  }

  /// Obraca kamerę o zadany przyrost kąta [deltaYaw] i [deltaPitch].
  PhotoCamera3dPose orbited({
    double deltaYaw = 0.0,
    double deltaPitch = 0.0,
  }) {
    return copyWith(
      yawDegrees: yawDegrees + deltaYaw,
      pitchDegrees: pitchDegrees + deltaPitch,
    );
  }

  static double _normalizeAngle(double angle) {
    var normalized = angle % 360.0;
    if (normalized > 180.0) normalized -= 360.0;
    if (normalized < -180.0) normalized += 360.0;
    return normalized;
  }
}

/// Ustawienia optyki obiektywu i głębi ostrości (Bokeh).
@immutable
class PhotoLensSettings {
  static const double minFocalLengthMm = 24.0;
  static const double maxFocalLengthMm = 200.0;
  static const double minApertureFStop = 1.4;
  static const double maxApertureFStop = 16.0;

  final double focalLengthMm;
  final double apertureFStop;
  final double focusDistanceMeters;
  final double bokehIntensity;
  final double vignetteIntensity;
  final double filmGrainIntensity;
  final bool showRuleOfThirdsGrid;

  const PhotoLensSettings({
    this.focalLengthMm = 50.0,
    this.apertureFStop = 2.8,
    this.focusDistanceMeters = 8.5,
    this.bokehIntensity = 0.48,
    this.vignetteIntensity = 0.28,
    this.filmGrainIntensity = 0.14,
    this.showRuleOfThirdsGrid = true,
  });

  PhotoLensSettings copyWith({
    double? focalLengthMm,
    double? apertureFStop,
    double? focusDistanceMeters,
    double? bokehIntensity,
    double? vignetteIntensity,
    double? filmGrainIntensity,
    bool? showRuleOfThirdsGrid,
  }) {
    return PhotoLensSettings(
      focalLengthMm:
          (focalLengthMm ?? this.focalLengthMm).clamp(minFocalLengthMm, maxFocalLengthMm),
      apertureFStop:
          (apertureFStop ?? this.apertureFStop).clamp(minApertureFStop, maxApertureFStop),
      focusDistanceMeters: (focusDistanceMeters ?? this.focusDistanceMeters).clamp(1.5, 60.0),
      bokehIntensity: (bokehIntensity ?? this.bokehIntensity).clamp(0.0, 1.0),
      vignetteIntensity: (vignetteIntensity ?? this.vignetteIntensity).clamp(0.0, 1.0),
      filmGrainIntensity: (filmGrainIntensity ?? this.filmGrainIntensity).clamp(0.0, 1.0),
      showRuleOfThirdsGrid: showRuleOfThirdsGrid ?? this.showRuleOfThirdsGrid,
    );
  }

  /// Pionowy kąt widzenia (FOV) dla pełnej klatki 35mm (wysokość matrycy 24 mm).
  double get verticalFovDegrees {
    final rad = 2.0 * math.atan(24.0 / (2.0 * focalLengthMm));
    return rad * 180.0 / math.pi;
  }

  /// Siła rozmycia tła (sigma Gaussa) wynikająca z przysłony i intensywności Bokeh.
  double get effectiveBlurSigma {
    final apertureFactor =
        ((maxApertureFStop - apertureFStop) / (maxApertureFStop - minApertureFStop))
            .clamp(0.0, 1.0);
    return (apertureFactor * bokehIntensity * 10.5).clamp(0.0, 10.5);
  }

  /// Opisowa kategoria ogniskowej obiektywu.
  String get lensCategoryLabel {
    if (focalLengthMm < 35.0) return 'Szeroki kąt';
    if (focalLengthMm <= 70.0) return 'Standard';
    if (focalLengthMm <= 135.0) return 'Portret / Tele';
    return 'Super Teleobiektyw';
  }
}

/// Zapisany zrzut ekranu w galerii Trybu Fotograficznego 3D.
@immutable
class PhotoGallerySavedEntry {
  final String id;
  final String filePath;
  final DateTime capturedAt;
  final String stageName;
  final double focalLengthMm;
  final double apertureFStop;
  final PhotoColorFilterPreset filterPreset;
  final int widthPx;
  final int heightPx;
  final int byteSize;

  const PhotoGallerySavedEntry({
    required this.id,
    required this.filePath,
    required this.capturedAt,
    required this.stageName,
    required this.focalLengthMm,
    required this.apertureFStop,
    required this.filterPreset,
    required this.widthPx,
    required this.heightPx,
    required this.byteSize,
  });
}

/// Wynik operacji zapisu zrzutu ekranu do galerii.
@immutable
class PhotoScreenshotSaveResult {
  final bool success;
  final String? filePath;
  final String? errorMessage;
  final PhotoGallerySavedEntry? entry;

  const PhotoScreenshotSaveResult({
    required this.success,
    this.filePath,
    this.errorMessage,
    this.entry,
  });
}

/// Pełny stan studia fotograficznego 3D przekazywany przy przechwyceniu kadru.
@immutable
class PhotoModeStudioState {
  final PhotoCamera3dPose pose;
  final PhotoLensSettings lens;
  final PhotoColorFilterPreset filterPreset;
  final double filterIntensity;
  final Offset focusPointNormalized;

  const PhotoModeStudioState({
    required this.pose,
    required this.lens,
    required this.filterPreset,
    required this.filterIntensity,
    required this.focusPointNormalized,
  });
}

typedef PhotoScreenshotCaptureCallback = Future<PhotoScreenshotSaveResult> Function(
  PhotoModeStudioState state,
  GlobalKey captureBoundaryKey,
);

/// Domyślny zapis zrzutów ekranu z [RepaintBoundary] do folderu galerii aplikacji.
class PhotoModeGalleryStorage {
  PhotoModeGalleryStorage._();

  static Future<PhotoScreenshotSaveResult> captureAndSaveToGallery({
    required GlobalKey captureBoundaryKey,
    required PhotoModeStudioState state,
    required String stageName,
    double pixelRatio = 2.0,
  }) async {
    try {
      final context = captureBoundaryKey.currentContext;
      if (context == null) {
        return const PhotoScreenshotSaveResult(
          success: false,
          errorMessage: 'Brak aktywnego bufora klatki 3D do przechwycenia.',
        );
      }
      final renderObject = context.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return const PhotoScreenshotSaveResult(
          success: false,
          errorMessage: 'Obiekt renderujący nie obsługuje zrzutu RepaintBoundary.',
        );
      }

      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final widthPx = image.width;
      final heightPx = image.height;
      image.dispose();

      if (byteData == null) {
        return const PhotoScreenshotSaveResult(
          success: false,
          errorMessage: 'Nie udało się zakodować obrazu PNG.',
        );
      }

      final bytes = byteData.buffer.asUint8List();
      final docsDir = await getApplicationDocumentsDirectory();
      final galleryDir = Directory(
        '${docsDir.path}${Platform.pathSeparator}pro_peloton_gallery',
      );
      if (!await galleryDir.exists()) {
        await galleryDir.create(recursive: true);
      }

      final now = DateTime.now();
      final id = 'ppm_${now.millisecondsSinceEpoch}';
      final filePath = '${galleryDir.path}${Platform.pathSeparator}$id.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      final entry = PhotoGallerySavedEntry(
        id: id,
        filePath: filePath,
        capturedAt: now,
        stageName: stageName,
        focalLengthMm: state.lens.focalLengthMm,
        apertureFStop: state.lens.apertureFStop,
        filterPreset: state.filterPreset,
        widthPx: widthPx,
        heightPx: heightPx,
        byteSize: bytes.length,
      );

      return PhotoScreenshotSaveResult(
        success: true,
        filePath: filePath,
        entry: entry,
      );
    } catch (error) {
      return PhotoScreenshotSaveResult(
        success: false,
        errorMessage: 'Błąd zapisu zdjęcia: $error',
      );
    }
  }
}

enum _StudioInspectorTab {
  camera('Kamera 3D', Icons.control_camera_rounded),
  lens('Obiektyw & Bokeh', Icons.camera_rounded),
  filters('Filtry', Icons.auto_awesome_rounded),
  gallery('Galeria', Icons.photo_library_rounded);

  final String label;
  final IconData icon;
  const _StudioInspectorTab(this.label, this.icon);
}

/// Tryb Fotograficzny 3D dostępny po zapauzowaniu wyścigu.
///
/// Oferuje swobodną kamerę 3D (Free Fly Cam), regulację ogniskowej obiektywu
/// (24 mm szeroki kąt – 200 mm teleobiektyw), głębię ostrości (Bokeh),
/// filtry kolorystyczne (Klasyczny Czarno-Biały 1970, Złota Godzina, Kontrast HDR)
/// oraz zapis zrzutów ekranu do galerii.
class PhotoMode3dCameraStudioOverlay extends StatefulWidget {
  final bool isRacePaused;
  final String stageName;
  final String raceTimeLabel;
  final Widget? childViewport;
  final PhotoCamera3dPose initialPose;
  final PhotoLensSettings initialLens;
  final PhotoColorFilterPreset initialFilter;
  final List<PhotoGallerySavedEntry> initialGallery;
  final ValueChanged<PhotoCamera3dPose>? onPoseChanged;
  final VoidCallback? onClose;
  final VoidCallback? onRequestPauseRace;
  final PhotoScreenshotCaptureCallback? onCaptureScreenshot;

  const PhotoMode3dCameraStudioOverlay({
    super.key,
    this.isRacePaused = true,
    this.stageName = "Etap 18 • Alpe d'Huez",
    this.raceTimeLabel = '03:42:18',
    this.childViewport,
    this.initialPose = const PhotoCamera3dPose(),
    this.initialLens = const PhotoLensSettings(),
    this.initialFilter = PhotoColorFilterPreset.natural,
    this.initialGallery = const <PhotoGallerySavedEntry>[],
    this.onPoseChanged,
    this.onClose,
    this.onRequestPauseRace,
    this.onCaptureScreenshot,
  });

  @override
  State<PhotoMode3dCameraStudioOverlay> createState() =>
      _PhotoMode3dCameraStudioOverlayState();
}

class _PhotoMode3dCameraStudioOverlayState extends State<PhotoMode3dCameraStudioOverlay>
    with SingleTickerProviderStateMixin {
  final GlobalKey _captureBoundaryKey = GlobalKey();
  final FocusNode _keyboardFocusNode = FocusNode(debugLabel: 'PhotoMode3dFocus');

  late PhotoCamera3dPose _pose;
  late PhotoLensSettings _lens;
  late PhotoColorFilterPreset _filterPreset;
  double _filterIntensity = 1.0;
  Offset _focusPointNormalized = const Offset(0.5, 0.52);

  _StudioInspectorTab _activeTab = _StudioInspectorTab.camera;
  bool _hideHudForCleanShot = false;
  bool _isCapturing = false;
  String? _statusMessage;
  bool _statusIsError = false;
  late List<PhotoGallerySavedEntry> _gallery;

  late final AnimationController _shutterFlashController;
  late final Animation<double> _shutterFlashOpacity;

  @override
  void initState() {
    super.initState();
    _pose = widget.initialPose;
    _lens = widget.initialLens;
    _filterPreset = widget.initialFilter;
    _gallery = List<PhotoGallerySavedEntry>.from(widget.initialGallery);

    _shutterFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _shutterFlashOpacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.0, end: 0.75)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem<double>(
        tween: Tween<double>(begin: 0.75, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
    ]).animate(_shutterFlashController);
  }

  @override
  void dispose() {
    _shutterFlashController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _updatePose(PhotoCamera3dPose nextPose) {
    setState(() {
      _pose = nextPose;
    });
    widget.onPoseChanged?.call(nextPose);
  }

  void _resetCameraAndOptics() {
    setState(() {
      _pose = widget.initialPose;
      _lens = widget.initialLens;
      _filterPreset = PhotoColorFilterPreset.natural;
      _filterIntensity = 1.0;
      _focusPointNormalized = const Offset(0.5, 0.52);
      _statusMessage = 'Zresetowano kamerę i ustawienia obiektywu.';
      _statusIsError = false;
    });
    widget.onPoseChanged?.call(_pose);
  }

  Future<void> _captureScreenshot() async {
    if (!widget.isRacePaused || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = null;
      _statusIsError = false;
    });

    unawaited(_shutterFlashController.forward(from: 0.0));

    final state = PhotoModeStudioState(
      pose: _pose,
      lens: _lens,
      filterPreset: _filterPreset,
      filterIntensity: _filterIntensity,
      focusPointNormalized: _focusPointNormalized,
    );

    final PhotoScreenshotSaveResult result;
    if (widget.onCaptureScreenshot != null) {
      result = await widget.onCaptureScreenshot!(state, _captureBoundaryKey);
    } else {
      result = await PhotoModeGalleryStorage.captureAndSaveToGallery(
        captureBoundaryKey: _captureBoundaryKey,
        state: state,
        stageName: widget.stageName,
      );
    }

    if (!mounted) return;
    setState(() {
      _isCapturing = false;
      if (result.success) {
        if (result.entry != null) {
          _gallery = <PhotoGallerySavedEntry>[result.entry!, ..._gallery];
        }
        _statusMessage = result.filePath != null
            ? 'Zapisano do galerii: ${result.filePath}'
            : 'Zapisano zdjęcie w galerii.';
        _statusIsError = false;
      } else {
        _statusMessage = result.errorMessage ?? 'Nie udało się zapisać zdjęcia.';
        _statusIsError = true;
      }
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!widget.isRacePaused) {
      return KeyEventResult.ignored;
    }

    final step = _pose.moveSpeedMetersPerSec * 0.25;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.keyW || key == LogicalKeyboardKey.arrowUp) {
      _updatePose(_pose.movedLocal(forward: step));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS || key == LogicalKeyboardKey.arrowDown) {
      _updatePose(_pose.movedLocal(forward: -step));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.arrowLeft) {
      _updatePose(_pose.movedLocal(right: -step));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyD || key == LogicalKeyboardKey.arrowRight) {
      _updatePose(_pose.movedLocal(right: step));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE) {
      _updatePose(_pose.movedLocal(up: step * 0.6));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyQ) {
      _updatePose(_pose.movedLocal(up: -step * 0.6));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      _resetCameraAndOptics();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyG) {
      setState(() {
        _lens = _lens.copyWith(showRuleOfThirdsGrid: !_lens.showRuleOfThirdsGrid);
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyH) {
      setState(() {
        _hideHudForCleanShot = !_hideHudForCleanShot;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      unawaited(_captureScreenshot());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Material(
        color: AppColors.background,
        child: DefaultTextStyle.merge(
          style: const TextStyle(
            fontFamily: 'Inter',
            letterSpacing: -0.2,
            color: AppColors.textPrimary,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              final isMobile = width < 680 || height < 620;
              final isDesktop = width >= 1220;

              if (!widget.isRacePaused) {
                return _buildPausedRequiredGate(width, height);
              }

              if (_hideHudForCleanShot) {
                return Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    _buildInteractiveViewport(),
                    _buildShutterFlashOverlay(),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: SafeArea(
                        child: _StudioActionButton(
                          key: const Key('photo_mode_show_hud_btn'),
                          icon: Icons.visibility_rounded,
                          label: 'Pokaż HUD',
                          onPressed: () {
                            setState(() => _hideHudForCleanShot = false);
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (isMobile) {
                return _buildMobileLayout(width, height);
              }
              return _buildWideLayout(isDesktop: isDesktop);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPausedRequiredGate(double width, double height) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryAccent),
                  ),
                  child: const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: AppColors.goldAccent,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tryb Fotograficzny 3D wymaga pauzy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Zatrzymaj symulację wyścigu, aby odblokować swobodną kamerę Free Fly Cam, regulację obiektywu oraz zapis zrzutu ekranu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    _StudioActionButton(
                      key: const Key('photo_mode_pause_race_btn'),
                      icon: Icons.pause_rounded,
                      label: 'Zapauzuj Wyścig',
                      isPrimary: true,
                      onPressed: widget.onRequestPauseRace,
                    ),
                    _StudioActionButton(
                      key: const Key('photo_mode_gate_close_btn'),
                      icon: Icons.close_rounded,
                      label: 'Wróć do wyścigu',
                      onPressed: widget.onClose,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(double width, double height) {
    final controlsHeight = (height * 0.44).clamp(260.0, 380.0);

    return SafeArea(
      child: Column(
        children: <Widget>[
          _buildTopStudioBar(compact: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: _buildViewportFrame(compact: true),
            ),
          ),
          SizedBox(
            height: controlsHeight,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
              ),
              child: Column(
                children: <Widget>[
                  _buildTabSelector(compact: true),
                  const Divider(height: 1, color: Color(0xFF2A2F3D)),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: _buildActiveTabBody(compact: true),
                    ),
                  ),
                  _buildBottomShutterBar(compact: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideLayout({required bool isDesktop}) {
    final inspectorWidth = isDesktop ? 356.0 : 308.0;

    return SafeArea(
      child: Column(
        children: <Widget>[
          _buildTopStudioBar(compact: false),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: _buildViewportFrame(compact: false),
                        ),
                        const SizedBox(height: 12),
                        _buildBottomShutterBar(compact: false),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: inspectorWidth,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2A2F3D),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          _buildTabSelector(compact: false),
                          const Divider(height: 1, color: Color(0xFF2A2F3D)),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(14),
                              child: _buildActiveTabBody(compact: false),
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
        ],
      ),
    );
  }

  Widget _buildTopStudioBar({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 18,
        vertical: compact ? 8 : 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2F3D), width: 1.0),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryAccent),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.camera_enhance_rounded,
                  size: 16,
                  color: AppColors.goldAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  compact ? 'STUDIO 3D' : 'TRYB FOTOGRAFICZNY 3D',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: AppColors.goldAccent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.stageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'PAUZA ${widget.raceTimeLabel} • ${_lens.focalLengthMm.round()} mm • f/${_lens.apertureFStop.toStringAsFixed(1)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!compact) ...<Widget>[
            _StudioActionButton(
              key: const Key('photo_mode_hide_hud_btn'),
              icon: Icons.visibility_off_rounded,
              label: 'Czysty kadr',
              onPressed: () {
                setState(() => _hideHudForCleanShot = true);
              },
            ),
            const SizedBox(width: 8),
          ],
          _StudioActionButton(
            key: const Key('photo_mode_reset_btn'),
            icon: Icons.refresh_rounded,
            label: compact ? '' : 'Reset',
            tooltip: 'Resetuj kamerę i obiektyw (R)',
            onPressed: _resetCameraAndOptics,
          ),
          const SizedBox(width: 8),
          _StudioActionButton(
            key: const Key('photo_mode_close_btn'),
            icon: Icons.close_rounded,
            label: compact ? '' : 'Zamknij',
            tooltip: 'Wyjdź z trybu fotograficznego',
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildViewportFrame({required bool compact}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          _buildInteractiveViewport(),
          _buildShutterFlashOverlay(),
          Positioned(
            top: 10,
            left: 10,
            child: _buildCameraTelemetryBadge(compact: compact),
          ),
          if (compact)
            Positioned(
              top: 10,
              right: 10,
              child: _StudioActionButton(
                key: const Key('photo_mode_hide_hud_btn'),
                icon: Icons.visibility_off_rounded,
                label: '',
                tooltip: 'Ukryj HUD',
                onPressed: () {
                  setState(() => _hideHudForCleanShot = true);
                },
              ),
            ),
          if (_statusMessage != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: _buildStatusBanner(),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractiveViewport() {
    final colorFilter = _filterPreset.buildColorFilter(intensity: _filterIntensity);
    final sigma = _lens.effectiveBlurSigma;

    Widget sceneContent = widget.childViewport ??
        CustomPaint(
          painter: _PhotoStudio3dScenePainter(
            pose: _pose,
            lens: _lens,
            focusPointNormalized: _focusPointNormalized,
          ),
          size: Size.infinite,
        );

    if (colorFilter != null) {
      sceneContent = ColorFiltered(
        colorFilter: colorFilter,
        child: sceneContent,
      );
    }

    final Widget filteredScene = Stack(
      fit: StackFit.expand,
      children: <Widget>[
        sceneContent,
        if (sigma > 0.15)
          IgnorePointer(
            child: ShaderMask(
              shaderCallback: (rect) {
                return RadialGradient(
                  center: Alignment(
                    _focusPointNormalized.dx * 2 - 1,
                    _focusPointNormalized.dy * 2 - 1,
                  ),
                  radius: 0.62,
                  colors: const <Color>[
                    Colors.transparent,
                    Colors.transparent,
                    Colors.white,
                  ],
                  stops: const <double>[0.0, 0.34, 1.0],
                ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
              },
              blendMode: BlendMode.dstIn,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: sceneContent,
              ),
            ),
          ),
        if (_lens.vignetteIntensity > 0.01)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.92,
                  colors: <Color>[
                    Colors.transparent,
                    Colors.black.withValues(alpha: _lens.vignetteIntensity * 0.72),
                  ],
                  stops: const <double>[0.45, 1.0],
                ),
              ),
            ),
          ),
        if (_lens.filmGrainIntensity > 0.01)
          IgnorePointer(
            child: CustomPaint(
              painter: _FilmGrainOverlayPainter(
                intensity: _lens.filmGrainIntensity,
              ),
            ),
          ),
      ],
    );

    return Listener(
      onPointerSignal: (pointerSignal) {
        if (pointerSignal is PointerScrollEvent) {
          final zoomDelta = pointerSignal.scrollDelta.dy > 0 ? 6.0 : -6.0;
          setState(() {
            _lens = _lens.copyWith(
              focalLengthMm: _lens.focalLengthMm + zoomDelta,
            );
          });
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox?;
          if (box == null || box.size.isEmpty) return;
          final local = details.localPosition;
          setState(() {
            _focusPointNormalized = Offset(
              (local.dx / box.size.width).clamp(0.1, 0.9),
              (local.dy / box.size.height).clamp(0.1, 0.9),
            );
          });
        },
        onPanUpdate: (details) {
          _updatePose(
            _pose.orbited(
              deltaYaw: details.delta.dx * 0.32,
              deltaPitch: -details.delta.dy * 0.24,
            ),
          );
        },
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            RepaintBoundary(
              key: _captureBoundaryKey,
              child: filteredScene,
            ),
            if (_lens.showRuleOfThirdsGrid)
              IgnorePointer(
                child: CustomPaint(
                  painter: _ViewfinderReticlePainter(
                    focusPointNormalized: _focusPointNormalized,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShutterFlashOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _shutterFlashOpacity,
        builder: (context, _) {
          final alpha = _shutterFlashOpacity.value;
          if (alpha <= 0.005) return const SizedBox.shrink();
          return ColoredBox(
            color: Colors.white.withValues(alpha: alpha),
          );
        },
      ),
    );
  }

  Widget _buildCameraTelemetryBadge({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Text(
        'FREE FLY  X:${_pose.positionX.toStringAsFixed(1)}  Y:${_pose.positionY.toStringAsFixed(1)}  Z:${_pose.positionZ.toStringAsFixed(1)}  •  FOV ${_lens.verticalFovDegrees.toStringAsFixed(1)}°',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final accent = _statusIsError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _statusIsError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusMessage ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector({required bool compact}) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: _StudioInspectorTab.values.map((tab) {
          final isSelected = _activeTab == tab;
          final badgeCount =
              tab == _StudioInspectorTab.gallery && _gallery.isNotEmpty
                  ? ' (${_gallery.length})'
                  : '';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _StudioTabButton(
                key: Key('photo_mode_tab_${tab.name}'),
                icon: tab.icon,
                label: compact ? tab.label.split(' ').first : '${tab.label}$badgeCount',
                selected: isSelected,
                onTap: () => setState(() => _activeTab = tab),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildActiveTabBody({required bool compact}) {
    switch (_activeTab) {
      case _StudioInspectorTab.camera:
        return _buildFreeFlyCameraTab(compact: compact);
      case _StudioInspectorTab.lens:
        return _buildLensAndBokehTab();
      case _StudioInspectorTab.filters:
        return _buildFiltersTab();
      case _StudioInspectorTab.gallery:
        return _buildGalleryTab();
    }
  }

  Widget _buildFreeFlyCameraTab({required bool compact}) {
    final step = _pose.moveSpeedMetersPerSec * 0.4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
          'SWOBODNA KAMERA 3D (FREE FLY CAM)',
          subtitle: 'Przeciągnij kadr, aby obracać • Klawisze WASD / Q-E',
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _buildDpadControls(step),
            ),
            const SizedBox(width: 10),
            Column(
              children: <Widget>[
                _StudioActionButton(
                  key: const Key('photo_mode_fly_up_btn'),
                  icon: Icons.arrow_upward_rounded,
                  label: 'W górę',
                  onPressed: () => _updatePose(_pose.movedLocal(up: step * 0.6)),
                ),
                const SizedBox(height: 8),
                _StudioActionButton(
                  key: const Key('photo_mode_fly_down_btn'),
                  icon: Icons.arrow_downward_rounded,
                  label: 'W dół',
                  onPressed: () => _updatePose(_pose.movedLocal(up: -step * 0.6)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildSliderRow(
          key: const Key('photo_mode_speed_slider'),
          label: 'Prędkość lotu kamery',
          valueLabel: '${_pose.moveSpeedMetersPerSec.toStringAsFixed(1)} m/s',
          value: _pose.moveSpeedMetersPerSec,
          min: 2.0,
          max: 30.0,
          onChanged: (v) => _updatePose(_pose.copyWith(moveSpeedMetersPerSec: v)),
        ),
        _buildSliderRow(
          key: const Key('photo_mode_roll_slider'),
          label: 'Przechył horyzontu (Dutch Angle)',
          valueLabel: '${_pose.rollDegrees.toStringAsFixed(0)}°',
          value: _pose.rollDegrees,
          min: -30.0,
          max: 30.0,
          onChanged: (v) => _updatePose(_pose.copyWith(rollDegrees: v)),
        ),
        if (!compact) ...<Widget>[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.touch_app_rounded, size: 16, color: AppColors.goldAccent),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kliknij dowolny punkt kadru, aby ustawić punkt ostrości AF.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDpadControls(double step) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: <Widget>[
          _StudioActionButton(
            key: const Key('photo_mode_fly_forward_btn'),
            icon: Icons.keyboard_arrow_up_rounded,
            label: 'Przód',
            onPressed: () => _updatePose(_pose.movedLocal(forward: step)),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: _StudioActionButton(
                  key: const Key('photo_mode_fly_left_btn'),
                  icon: Icons.keyboard_arrow_left_rounded,
                  label: 'Lewo',
                  onPressed: () => _updatePose(_pose.movedLocal(right: -step)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _StudioActionButton(
                  key: const Key('photo_mode_fly_right_btn'),
                  icon: Icons.keyboard_arrow_right_rounded,
                  label: 'Prawo',
                  onPressed: () => _updatePose(_pose.movedLocal(right: step)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _StudioActionButton(
            key: const Key('photo_mode_fly_back_btn'),
            icon: Icons.keyboard_arrow_down_rounded,
            label: 'Tył',
            onPressed: () => _updatePose(_pose.movedLocal(forward: -step)),
          ),
        ],
      ),
    );
  }

  Widget _buildLensAndBokehTab() {
    const primeLengths = <double>[24, 35, 50, 85, 135, 200];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
          'OBIEKTYW I GŁĘBIA OSTROŚCI (BOKEH)',
          subtitle: '${_lens.lensCategoryLabel} • FOV ${_lens.verticalFovDegrees.toStringAsFixed(1)}°',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: primeLengths.map((mm) {
            final isSelected = (_lens.focalLengthMm - mm).abs() < 2.0;
            return _StudioPresetChip(
              key: Key('photo_mode_focal_${mm.round()}mm'),
              label: '${mm.round()} mm',
              selected: isSelected,
              onTap: () => setState(() {
                _lens = _lens.copyWith(focalLengthMm: mm);
              }),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 12),
        _buildSliderRow(
          key: const Key('photo_mode_focal_slider'),
          label: 'Ogniskowa obiektywu',
          valueLabel: '${_lens.focalLengthMm.round()} mm',
          value: _lens.focalLengthMm,
          min: PhotoLensSettings.minFocalLengthMm,
          max: PhotoLensSettings.maxFocalLengthMm,
          onChanged: (v) => setState(() {
            _lens = _lens.copyWith(focalLengthMm: v);
          }),
        ),
        _buildSliderRow(
          key: const Key('photo_mode_aperture_slider'),
          label: 'Przysłona (Bokeh)',
          valueLabel: 'f/${_lens.apertureFStop.toStringAsFixed(1)}',
          value: _lens.apertureFStop,
          min: PhotoLensSettings.minApertureFStop,
          max: PhotoLensSettings.maxApertureFStop,
          onChanged: (v) => setState(() {
            _lens = _lens.copyWith(apertureFStop: v);
          }),
        ),
        _buildSliderRow(
          key: const Key('photo_mode_bokeh_intensity_slider'),
          label: 'Intensywność rozmycia tła',
          valueLabel: '${(_lens.bokehIntensity * 100).round()}%',
          value: _lens.bokehIntensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => setState(() {
            _lens = _lens.copyWith(bokehIntensity: v);
          }),
        ),
        _buildSliderRow(
          key: const Key('photo_mode_focus_distance_slider'),
          label: 'Dystans ostrzenia (AF)',
          valueLabel: '${_lens.focusDistanceMeters.toStringAsFixed(1)} m',
          value: _lens.focusDistanceMeters,
          min: 1.5,
          max: 60.0,
          onChanged: (v) => setState(() {
            _lens = _lens.copyWith(focusDistanceMeters: v);
          }),
        ),
        const SizedBox(height: 6),
        _StudioToggleTile(
          key: const Key('photo_mode_grid_toggle'),
          title: 'Siatka trójpodziału (Rule of Thirds)',
          value: _lens.showRuleOfThirdsGrid,
          onChanged: (val) => setState(() {
            _lens = _lens.copyWith(showRuleOfThirdsGrid: val);
          }),
        ),
      ],
    );
  }

  Widget _buildFiltersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
          'FILTRY KOLORYSTYCZNE',
          subtitle: 'Korekcja barwna i charakterystyka kliszy',
        ),
        const SizedBox(height: 10),
        ...PhotoColorFilterPreset.values.map((preset) {
          final isSelected = _filterPreset == preset;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StudioFilterOptionCard(
              key: Key('photo_mode_filter_${preset.id}'),
              preset: preset,
              selected: isSelected,
              onTap: () => setState(() => _filterPreset = preset),
            ),
          );
        }),
        const SizedBox(height: 6),
        _buildSliderRow(
          key: const Key('photo_mode_filter_intensity_slider'),
          label: 'Siła filtra',
          valueLabel: '${(_filterIntensity * 100).round()}%',
          value: _filterIntensity,
          min: 0.0,
          max: 1.0,
          enabled: _filterPreset != PhotoColorFilterPreset.natural,
          onChanged: (v) => setState(() => _filterIntensity = v),
        ),
        _buildSliderRow(
          key: const Key('photo_mode_vignette_slider'),
          label: 'Winieta obiektywu',
          valueLabel: '${(_lens.vignetteIntensity * 100).round()}%',
          value: _lens.vignetteIntensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => setState(() {
            _lens = _lens.copyWith(vignetteIntensity: v);
          }),
        ),
        _buildSliderRow(
          key: const Key('photo_mode_grain_slider'),
          label: 'Ziarno filmu (35mm)',
          valueLabel: '${(_lens.filmGrainIntensity * 100).round()}%',
          value: _lens.filmGrainIntensity,
          min: 0.0,
          max: 1.0,
          onChanged: (v) => setState(() {
            _lens = _lens.copyWith(filmGrainIntensity: v);
          }),
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    if (_gallery.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Column(
          children: <Widget>[
            Icon(
              Icons.photo_camera_back_rounded,
              size: 32,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 10),
            Text(
              'Brak zapisanych zdjęć',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Ustaw kadr i naciśnij "Zrób Zdjęcie" (lub Spację), aby zapisać zrzut ekranu do galerii.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildSectionTitle(
          'GALERIA SESJI (${_gallery.length})',
          subtitle: 'Zapisane zrzuty ekranu PNG',
        ),
        const SizedBox(height: 10),
        ..._gallery.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryAccent),
                  ),
                  child: const Icon(
                    Icons.image_rounded,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${entry.focalLengthMm.round()} mm • f/${entry.apertureFStop.toStringAsFixed(1)} • ${entry.filterPreset.shortLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        '${entry.widthPx}×${entry.heightPx} px • ${(entry.byteSize / 1024).toStringAsFixed(0)} KB',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Usuń z listy',
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  color: AppColors.textSecondary,
                  onPressed: () {
                    setState(() {
                      _gallery = _gallery
                          .where((item) => item.id != entry.id)
                          .toList(growable: false);
                    });
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomShutterBar({required bool compact}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: compact ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: compact
            ? const BorderRadius.vertical(bottom: Radius.circular(15))
            : BorderRadius.circular(16),
        border: compact
            ? const Border(top: BorderSide(color: Color(0xFF2A2F3D)))
            : Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: <Widget>[
          if (!compact)
            Expanded(
              child: Text(
                'Filtr: ${_filterPreset.label} • Galeria: ${_gallery.length}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          if (compact)
            Expanded(
              child: Text(
                '${_lens.focalLengthMm.round()}mm • ${_filterPreset.shortLabel}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          const SizedBox(width: 10),
          _StudioActionButton(
            key: const Key('photo_mode_shutter_btn'),
            icon: _isCapturing
                ? Icons.hourglass_top_rounded
                : Icons.camera_alt_rounded,
            label: _isCapturing ? 'Zapisywanie...' : 'Zrób Zdjęcie',
            isPrimary: true,
            enabled: widget.isRacePaused && !_isCapturing,
            onPressed: _captureScreenshot,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: AppColors.goldAccent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow({
    required Key key,
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  valueLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldAccent,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primaryAccent,
                inactiveTrackColor: AppColors.surfaceLight,
                thumbColor: AppColors.goldAccent,
                overlayColor: AppColors.goldAccent.withValues(alpha: 0.18),
                trackHeight: 4,
              ),
              child: Slider(
                key: key,
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudioActionButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onPressed;

  const _StudioActionButton({
    super.key,
    required this.icon,
    required this.label,
    this.tooltip,
    this.isPrimary = false,
    this.enabled = true,
    this.onPressed,
  });

  @override
  State<_StudioActionButton> createState() => _StudioActionButtonState();
}

class _StudioActionButtonState extends State<_StudioActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.enabled || widget.onPressed == null;
    final bgColor = widget.isPrimary
        ? (_pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.8)
            : _hovered
                ? const Color(0xFFA35756)
                : AppColors.primaryAccent)
        : (_pressed
            ? AppColors.surfaceLight
            : _hovered
                ? const Color(0xFF282D3A)
                : AppColors.surfaceLight);

    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isPrimary
            ? AppColors.goldAccent.withValues(alpha: _hovered ? 0.9 : 0.45)
            : const Color(0xFF2A2F3D);

    final Widget content = FocusableActionDetector(
      enabled: !isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: GestureDetector(
          onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
          onTapCancel: isDisabled ? null : () => setState(() => _pressed = false),
          onTapUp: isDisabled ? null : (_) => setState(() => _pressed = false),
          onTap: isDisabled ? null : widget.onPressed,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isDisabled ? 0.45 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.label.isEmpty ? 9 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.isPrimary ? Colors.white : AppColors.textPrimary,
                  ),
                  if (widget.label.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.isPrimary ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(message: widget.tooltip!, child: content);
    }
    return content;
  }
}

class _StudioTabButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StudioTabButton({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_StudioTabButton> createState() => _StudioTabButtonState();
}

class _StudioTabButtonState extends State<_StudioTabButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.22)
                  : _hovered
                      ? AppColors.surfaceLight
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : widget.selected
                        ? AppColors.primaryAccent
                        : Colors.transparent,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 16,
                  color: widget.selected ? AppColors.goldAccent : AppColors.textSecondary,
                ),
                const SizedBox(height: 3),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected ? AppColors.textPrimary : AppColors.textSecondary,
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

class _StudioPresetChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StudioPresetChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_StudioPresetChip> createState() => _StudioPresetChipState();
}

class _StudioPresetChipState extends State<_StudioPresetChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.goldAccent.withValues(alpha: 0.16)
                  : _hovered
                      ? const Color(0xFF282D3A)
                      : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused || widget.selected
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.selected ? AppColors.goldAccent : AppColors.textPrimary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioFilterOptionCard extends StatefulWidget {
  final PhotoColorFilterPreset preset;
  final bool selected;
  final VoidCallback onTap;

  const _StudioFilterOptionCard({
    super.key,
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_StudioFilterOptionCard> createState() => _StudioFilterOptionCardState();
}

class _StudioFilterOptionCardState extends State<_StudioFilterOptionCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.selected
                  ? AppColors.primaryAccent.withValues(alpha: 0.16)
                  : _hovered
                      ? const Color(0xFF282D3A)
                      : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused || widget.selected
                    ? AppColors.goldAccent
                    : AppColors.cardBorder,
                width: widget.selected ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 14,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.preset.accentColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.preset.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.preset.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.goldAccent,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StudioToggleTile extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StudioToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.goldAccent,
            activeTrackColor: AppColors.primaryAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Rzutnik sceny 3D dla podglądu Trybu Fotograficznego, gdy nie przekazano zewnętrznego viewportu.
class _PhotoStudio3dScenePainter extends CustomPainter {
  final PhotoCamera3dPose pose;
  final PhotoLensSettings lens;
  final Offset focusPointNormalized;

  const _PhotoStudio3dScenePainter({
    required this.pose,
    required this.lens,
    required this.focusPointNormalized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    canvas.save();
    final center = Offset(size.width * 0.5, size.height * 0.5);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(pose.rollDegrees * math.pi / 180.0);
    canvas.translate(-center.dx, -center.dy);

    final horizonY =
        (size.height * (0.48 - pose.pitchDegrees / 140.0)).clamp(40.0, size.height * 0.8);

    // Niebo alpejskie
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF14213D),
          Color(0xFF2B4162),
          Color(0xFFE09F3E),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, horizonY), skyPaint);

    // Szczyty górskie reagujące na yaw i ogniskową
    final zoomScale = (lens.focalLengthMm / 50.0).clamp(0.45, 3.8);
    final yawShift = -pose.yawDegrees * 2.2 * zoomScale;

    final mountainPath = Path()..moveTo(0, horizonY);
    for (int i = 0; i <= 8; i++) {
      final t = i / 8.0;
      final x = t * size.width;
      final peak = math.sin(t * math.pi * 3.0 + yawShift * 0.015) * 34.0 +
          math.cos(t * math.pi * 5.0) * 18.0;
      mountainPath.lineTo(x, horizonY - 28.0 - peak.abs() * 0.7);
    }
    mountainPath
      ..lineTo(size.width, horizonY)
      ..close();
    canvas.drawPath(mountainPath, Paint()..color = const Color(0xFF1E293B));

    // Teren i szosa w perspektywie
    canvas.drawRect(
      Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY),
      Paint()..color = const Color(0xFF1B241E),
    );

    final roadCenterAtBottom =
        size.width * 0.5 - pose.positionX * 14.0 * zoomScale + yawShift * 0.4;
    final roadTopX = size.width * 0.5 + yawShift * 0.25;
    final roadHalfBottom = size.width * 0.36 * (0.85 + 0.25 / zoomScale);
    final roadHalfTop = 10.0 * zoomScale.clamp(0.6, 2.2);

    final roadPath = Path()
      ..moveTo(roadTopX - roadHalfTop, horizonY)
      ..lineTo(roadTopX + roadHalfTop, horizonY)
      ..lineTo(roadCenterAtBottom + roadHalfBottom, size.height)
      ..lineTo(roadCenterAtBottom - roadHalfBottom, size.height)
      ..close();
    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF2B303A));

    // Przerywana linia osi jezdni
    final linePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.75)
      ..strokeWidth = 2.0;
    for (int seg = 0; seg < 6; seg++) {
      final t0 = seg / 6.0;
      final t1 = (seg + 0.5) / 6.0;
      final y0 = horizonY + (size.height - horizonY) * (t0 * t0);
      final y1 = horizonY + (size.height - horizonY) * (t1 * t1);
      final x0 = roadTopX + (roadCenterAtBottom - roadTopX) * (t0 * t0);
      final x1 = roadTopX + (roadCenterAtBottom - roadTopX) * (t1 * t1);
      canvas.drawLine(Offset(x0, y0), Offset(x1, y1), linePaint);
    }

    // Sylwetki kolarzy w 3D (rzutowane wg pozycji kamery i ogniskowej)
    const riderOffsets = <Offset>[
      Offset(0.0, 0.0),
      Offset(-1.3, 1.8),
      Offset(1.4, 2.4),
      Offset(-0.4, 4.2),
      Offset(1.8, 5.1),
    ];

    final jerseyColors = <Color>[
      AppColors.goldAccent,
      AppColors.primaryAccent,
      AppColors.accentBlue,
      AppColors.statusSuccess,
      AppColors.textPrimary,
    ];

    for (int i = riderOffsets.length - 1; i >= 0; i--) {
      final relZ = (riderOffsets[i].dy - pose.positionZ).clamp(2.5, 45.0);
      final perspective = (14.0 * zoomScale) / relZ;
      final rx = roadCenterAtBottom +
          (riderOffsets[i].dx - pose.positionX * 0.2) * 28.0 * perspective;
      final ry = horizonY + (size.height - horizonY) * (0.28 + 0.55 * perspective.clamp(0.1, 1.1));
      final rScale = (perspective * 16.0).clamp(6.0, 42.0);

      // Cień pod kolarzem
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry + rScale * 0.8), width: rScale * 1.4, height: rScale * 0.35),
        Paint()..color = Colors.black.withValues(alpha: 0.45),
      );

      // Koła i sylwetka
      final wheelPaint = Paint()
        ..color = const Color(0xFF111318)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (rScale * 0.14).clamp(1.5, 4.0);
      canvas.drawCircle(Offset(rx, ry + rScale * 0.42), rScale * 0.36, wheelPaint);

      // Koszulka
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(rx, ry - rScale * 0.08), width: rScale * 0.65, height: rScale * 0.72),
          Radius.circular(rScale * 0.2),
        ),
        Paint()..color = jerseyColors[i],
      );

      // Kask
      canvas.drawCircle(
        Offset(rx, ry - rScale * 0.62),
        rScale * 0.24,
        Paint()..color = Colors.white,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PhotoStudio3dScenePainter oldDelegate) {
    return oldDelegate.pose != pose ||
        oldDelegate.lens != lens ||
        oldDelegate.focusPointNormalized != focusPointNormalized;
  }
}

class _ViewfinderReticlePainter extends CustomPainter {
  final Offset focusPointNormalized;

  const _ViewfinderReticlePainter({required this.focusPointNormalized});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1.0;

    for (int i = 1; i <= 2; i++) {
      final x = size.width * (i / 3.0);
      final y = size.height * (i / 3.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Punkt AF
    final focusCenter = Offset(
      focusPointNormalized.dx * size.width,
      focusPointNormalized.dy * size.height,
    );
    final afPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(focusCenter, 16, afPaint);
    canvas.drawCircle(
      focusCenter,
      2.5,
      Paint()..color = AppColors.goldAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewfinderReticlePainter oldDelegate) {
    return oldDelegate.focusPointNormalized != focusPointNormalized;
  }
}

class _FilmGrainOverlayPainter extends CustomPainter {
  final double intensity;

  const _FilmGrainOverlayPainter({required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final alpha = (intensity * 0.14).clamp(0.0, 0.14);
    if (alpha <= 0.002) return;

    final random = math.Random(1970);
    final paint = Paint()..color = Colors.white.withValues(alpha: alpha);
    const count = 180;
    for (int i = 0; i < count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1.5, 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FilmGrainOverlayPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}
