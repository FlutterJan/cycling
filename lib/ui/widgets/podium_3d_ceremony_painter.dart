import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Typ koszulki lidera prezentowanej na podium dekoracji po etapie.
enum PodiumLeaderJerseyType {
  yellow('Żółta (GC)', 'GC', Color(0xFFFACC15), Color(0xFF181B22)),
  green('Zielona (Punkty)', 'PTS', Color(0xFF10B981), Color(0xFF064E3B)),
  polkaDot('W Grochy (KOM)', 'KOM', Color(0xFFF3F4F6), Color(0xFFEF4444)),
  white('Biała (Młodzież)', 'U23', Color(0xFFF3F4F6), Color(0xFF38BDF8)),
  stageWinner('Zwycięzca Etapu', 'STG', Color(0xFFD4AF37), Color(0xFF8E4A49));

  final String label;
  final String shortCode;
  final Color primaryColor;
  final Color accentColor;

  const PodiumLeaderJerseyType(
    this.label,
    this.shortCode,
    this.primaryColor,
    this.accentColor,
  );
}

/// Motyw kolorystyczny wyścigu sterujący barwami konfetti, reflektorów i ścianki.
enum PodiumCeremonyRaceTheme {
  tourDeFrance(
    title: 'Grand Tour — Klasyfikacja Generalna',
    confettiColors: <Color>[
      Color(0xFFFACC15),
      Color(0xFF10B981),
      Color(0xFFEF4444),
      Color(0xFFF3F4F6),
      Color(0xFFD4AF37),
    ],
    spotlightTint: Color(0xFFD4AF37),
  ),
  giroDItalia(
    title: 'Corsa Rosa — Podium Etapu',
    confettiColors: <Color>[
      Color(0xFFEC4899),
      Color(0xFF38BDF8),
      Color(0xFFD4AF37),
      Color(0xFFF3F4F6),
    ],
    spotlightTint: Color(0xFFEC4899),
  ),
  vueltaAEspana(
    title: 'La Vuelta — Dekoracja Zwycięzców',
    confettiColors: <Color>[
      Color(0xFFEF4444),
      Color(0xFFD4AF37),
      Color(0xFF10B981),
      Color(0xFFF3F4F6),
    ],
    spotlightTint: Color(0xFFEF4444),
  ),
  worldTour(
    title: 'UCI WorldTour — Ceremonia Podium',
    confettiColors: <Color>[
      Color(0xFFD4AF37),
      Color(0xFF8E4A49),
      Color(0xFF38BDF8),
      Color(0xFF00E5FF),
      Color(0xFFF3F4F6),
    ],
    spotlightTint: Color(0xFF38BDF8),
  );

  final String title;
  final List<Color> confettiColors;
  final Color spotlightTint;

  const PodiumCeremonyRaceTheme({
    required this.title,
    required this.confettiColors,
    required this.spotlightTint,
  });
}

/// Dane pojedynczego kolarza stojącego na stopniu podium dekoracji.
class PodiumRiderEntry {
  final int position;
  final String riderName;
  final String teamName;
  final String nationalityCode;
  final String timeOrGap;
  final Color teamColor;
  final PodiumLeaderJerseyType jerseyType;
  final bool isPlayerTeam;

  const PodiumRiderEntry({
    required this.position,
    required this.riderName,
    required this.teamName,
    required this.nationalityCode,
    required this.timeOrGap,
    required this.teamColor,
    required this.jerseyType,
    this.isPlayerTeam = false,
  });
}

/// Profil hymnu narodowego zwycięzcy etapu (tytuł, barwy flagi i linia melodyczna).
class PodiumNationalAnthemProfile {
  final String nationalityCode;
  final String countryName;
  final String anthemTitle;
  final List<Color> flagColors;
  final List<double> melodyFrequenciesHz;

  const PodiumNationalAnthemProfile({
    required this.nationalityCode,
    required this.countryName,
    required this.anthemTitle,
    required this.flagColors,
    required this.melodyFrequenciesHz,
  });

  /// Zwraca profil hymnu dla podanego kodu kraju ISO-3 (z bezpiecznym fallbackiem).
  static PodiumNationalAnthemProfile forCountry(String code) {
    final normalized = code.trim().toUpperCase();
    return _catalog[normalized] ??
        PodiumNationalAnthemProfile(
          nationalityCode: normalized.isEmpty ? 'UCI' : normalized,
          countryName: normalized.isEmpty ? 'Międzynarodowy' : normalized,
          anthemTitle: 'Hymn Narodowy ($normalized)',
          flagColors: const <Color>[
            Color(0xFF38BDF8),
            Color(0xFFF3F4F6),
            Color(0xFFD4AF37),
          ],
          melodyFrequenciesHz: const <double>[
            392.0,
            440.0,
            493.88,
            523.25,
            587.33,
            523.25,
            493.88,
            440.0,
          ],
        );
  }

  /// Syntetyzuje próbki PCM (16-bit mono, 44.1 kHz) dla hymnu zwycięzcy.
  Uint8List synthesizePreviewPcm({int sampleRate = 44100}) {
    const double noteDurationSec = 0.28;
    final int samplesPerNote = (sampleRate * noteDurationSec).round();
    final int totalSamples = samplesPerNote * melodyFrequenciesHz.length;
    final ByteData buffer = ByteData(totalSamples * 2);

    for (int n = 0; n < melodyFrequenciesHz.length; n++) {
      final double freq = melodyFrequenciesHz[n];
      for (int i = 0; i < samplesPerNote; i++) {
        final double t = i / sampleRate;
        final double progress = i / samplesPerNote;
        final double attack = (progress / 0.12).clamp(0.0, 1.0);
        final double release = ((1.0 - progress) / 0.25).clamp(0.0, 1.0);
        final double envelope = attack * release;
        final double fundamental = math.sin(2 * math.pi * freq * t);
        final double brassHarmonic = 0.35 * math.sin(4 * math.pi * freq * t);
        final double sample = (fundamental + brassHarmonic) * 0.45 * envelope;
        final int pcm = (sample * 32767).round().clamp(-32768, 32767);
        buffer.setInt16((n * samplesPerNote + i) * 2, pcm, Endian.little);
      }
    }
    return buffer.buffer.asUint8List();
  }

  static const Map<String, PodiumNationalAnthemProfile> _catalog =
      <String, PodiumNationalAnthemProfile>{
    'POL': PodiumNationalAnthemProfile(
      nationalityCode: 'POL',
      countryName: 'Polska',
      anthemTitle: 'Mazurek Dąbrowskiego',
      flagColors: <Color>[Color(0xFFF3F4F6), Color(0xFFDC2626)],
      melodyFrequenciesHz: <double>[
        392.0, 440.0, 493.88, 440.0, 392.0, 329.63, 293.66, 392.0,
      ],
    ),
    'SLO': PodiumNationalAnthemProfile(
      nationalityCode: 'SLO',
      countryName: 'Słowenia',
      anthemTitle: 'Zdravljica',
      flagColors: <Color>[
        Color(0xFFF3F4F6),
        Color(0xFF2563EB),
        Color(0xFFDC2626),
      ],
      melodyFrequenciesHz: <double>[
        329.63, 392.0, 440.0, 523.25, 493.88, 440.0, 392.0, 329.63,
      ],
    ),
    'FRA': PodiumNationalAnthemProfile(
      nationalityCode: 'FRA',
      countryName: 'Francja',
      anthemTitle: 'La Marseillaise',
      flagColors: <Color>[
        Color(0xFF2563EB),
        Color(0xFFF3F4F6),
        Color(0xFFDC2626),
      ],
      melodyFrequenciesHz: <double>[
        293.66, 392.0, 392.0, 440.0, 493.88, 587.33, 493.88, 392.0,
      ],
    ),
    'BEL': PodiumNationalAnthemProfile(
      nationalityCode: 'BEL',
      countryName: 'Belgia',
      anthemTitle: 'La Brabançonne',
      flagColors: <Color>[
        Color(0xFF111827),
        Color(0xFFFACC15),
        Color(0xFFDC2626),
      ],
      melodyFrequenciesHz: <double>[
        349.23, 440.0, 523.25, 587.33, 523.25, 466.16, 440.0, 349.23,
      ],
    ),
    'DEN': PodiumNationalAnthemProfile(
      nationalityCode: 'DEN',
      countryName: 'Dania',
      anthemTitle: 'Der er et yndigt land',
      flagColors: <Color>[Color(0xFFDC2626), Color(0xFFF3F4F6)],
      melodyFrequenciesHz: <double>[
        392.0, 493.88, 587.33, 523.25, 493.88, 440.0, 392.0, 329.63,
      ],
    ),
    'NED': PodiumNationalAnthemProfile(
      nationalityCode: 'NED',
      countryName: 'Holandia',
      anthemTitle: 'Het Wilhelmus',
      flagColors: <Color>[
        Color(0xFFDC2626),
        Color(0xFFF3F4F6),
        Color(0xFF2563EB),
      ],
      melodyFrequenciesHz: <double>[
        293.66, 392.0, 440.0, 493.88, 523.25, 493.88, 440.0, 392.0,
      ],
    ),
    'ESP': PodiumNationalAnthemProfile(
      nationalityCode: 'ESP',
      countryName: 'Hiszpania',
      anthemTitle: 'Marcha Real',
      flagColors: <Color>[
        Color(0xFFDC2626),
        Color(0xFFFACC15),
        Color(0xFFDC2626),
      ],
      melodyFrequenciesHz: <double>[
        392.0, 523.25, 493.88, 440.0, 392.0, 440.0, 493.88, 523.25,
      ],
    ),
    'ITA': PodiumNationalAnthemProfile(
      nationalityCode: 'ITA',
      countryName: 'Włochy',
      anthemTitle: 'Il Canto degli Italiani',
      flagColors: <Color>[
        Color(0xFF10B981),
        Color(0xFFF3F4F6),
        Color(0xFFDC2626),
      ],
      melodyFrequenciesHz: <double>[
        349.23, 392.0, 440.0, 523.25, 587.33, 523.25, 440.0, 349.23,
      ],
    ),
    'GBR': PodiumNationalAnthemProfile(
      nationalityCode: 'GBR',
      countryName: 'Wielka Brytania',
      anthemTitle: 'God Save the King',
      flagColors: <Color>[
        Color(0xFF1D4ED8),
        Color(0xFFF3F4F6),
        Color(0xFFDC2626),
      ],
      melodyFrequenciesHz: <double>[
        392.0, 392.0, 440.0, 349.23, 392.0, 440.0, 493.88, 523.25,
      ],
    ),
    'COL': PodiumNationalAnthemProfile(
      nationalityCode: 'COL',
      countryName: 'Kolumbia',
      anthemTitle: 'Himno Nacional de Colombia',
      flagColors: <Color>[
        Color(0xFFFACC15),
        Color(0xFF2563EB),
        Color(0xFFDC2626),
      ],
      melodyFrequenciesHz: <double>[
        440.0, 523.25, 587.33, 659.25, 587.33, 523.25, 493.88, 440.0,
      ],
    ),
  };
}

/// Rzutnik 3D na `CustomPainter` renderujący pełną scenę ceremonii podium po etapie:
/// - 3 stopnie podium w rzucie perspektywicznym 3D (2. srebro, 1. złoto, 3. brąz),
/// - kolarzy w koszulkach lidera (Żółta, Zielona, W Grochy, Biała),
/// - konfetti w barwach wyścigu,
/// - błyski fleszy fotoreporterów z rozbłyskiem soczewkowym,
/// - projekcję flagi i equalizer hymnu narodowego zwycięzcy.
class Podium3dCeremonyPainter extends CustomPainter {
  final List<PodiumRiderEntry> podiumRiders;
  final double ceremonyTime;
  final double podiumRiseProgress;
  final PodiumCeremonyRaceTheme raceTheme;
  final PodiumLeaderJerseyType? highlightedJersey;
  final int? hoveredPosition;
  final int? selectedPosition;
  final bool showConfetti;
  final bool showCameraFlashes;
  final bool isAnthemPlaying;
  final double manualFlashBoost;
  final String stageTitle;

  const Podium3dCeremonyPainter({
    required this.podiumRiders,
    required this.ceremonyTime,
    required this.podiumRiseProgress,
    this.raceTheme = PodiumCeremonyRaceTheme.tourDeFrance,
    this.highlightedJersey,
    this.hoveredPosition,
    this.selectedPosition,
    this.showConfetti = true,
    this.showCameraFlashes = true,
    this.isAnthemPlaying = true,
    this.manualFlashBoost = 0.0,
    this.stageTitle = 'CEREMONIA DEKORACJI',
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1 || size.height <= 1) return;

    final Rect bounds = Offset.zero & size;
    canvas.save();
    canvas.clipRect(bounds);

    _paintArenaBackground(canvas, size);
    _paintSpotlights(canvas, size);
    _paintSponsorBackdropWall(canvas, size);
    _paintWinnerFlagProjection(canvas, size);
    _paintStageFloor(canvas, size);
    _paintThreeStep3dPodium(canvas, size);
    _paintCrowdSilhouettes(canvas, size);
    if (showCameraFlashes) {
      _paintPhotographerFlashes(canvas, size);
    }
    if (showConfetti) {
      _paintRaceConfetti(canvas, size);
    }
    if (isAnthemPlaying) {
      _paintAnthemEqualizerRibbon(canvas, size);
    }

    canvas.restore();
  }

  void _paintArenaBackground(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          AppColors.background,
          Color(0xFF13161D),
          AppColors.surface,
        ],
        stops: <double>[0.0, 0.58, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Subtelny krąg światła za podium
    final Offset center = Offset(size.width * 0.5, size.height * 0.44);
    final Paint haloPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          raceTheme.spotlightTint.withValues(alpha: 0.16),
          AppColors.primaryAccent.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.55),
      );
    canvas.drawCircle(center, size.width * 0.55, haloPaint);
  }

  void _paintSpotlights(Canvas canvas, Size size) {
    final List<double> sourceX = <double>[0.18, 0.5, 0.82];
    final List<double> targetX = <double>[0.32, 0.5, 0.68];

    for (int i = 0; i < sourceX.length; i++) {
      final double sway = math.sin(ceremonyTime * 1.4 + i * 1.7) * 0.04;
      final Offset origin = Offset(size.width * sourceX[i], -12);
      final double tx = size.width * (targetX[i] + sway);
      final double spread = size.width * (i == 1 ? 0.15 : 0.11);

      final Path beam = Path()
        ..moveTo(origin.dx - 8, origin.dy)
        ..lineTo(origin.dx + 8, origin.dy)
        ..lineTo(tx + spread, size.height * 0.84)
        ..lineTo(tx - spread, size.height * 0.84)
        ..close();

      final Color beamColor =
          i == 1 ? AppColors.goldAccent : raceTheme.spotlightTint;
      final Paint beamPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            beamColor.withValues(alpha: 0.22),
            beamColor.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ).createShader(Offset.zero & size);
      canvas.drawPath(beam, beamPaint);
    }
  }

  void _paintSponsorBackdropWall(Canvas canvas, Size size) {
    final double wallW = size.width * 0.78;
    final double wallH = size.height * 0.34;
    final double wallLeft = (size.width - wallW) / 2;
    final double wallTop = size.height * 0.12;
    final RRect wallRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(wallLeft, wallTop, wallW, wallH),
      const Radius.circular(14),
    );

    final Paint wallPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          AppColors.surface,
          AppColors.surfaceLight,
          AppColors.surface,
        ],
      ).createShader(wallRect.outerRect);
    canvas.drawRRect(wallRect, wallPaint);

    // Pasek dekoracyjny na górze ścianki sponsorskiej
    final Paint topStrip = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          AppColors.primaryAccent,
          AppColors.goldAccent,
          raceTheme.spotlightTint,
        ],
      ).createShader(Rect.fromLTWH(wallLeft, wallTop, wallW, 5));
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(wallLeft, wallTop, wallW, 5),
        topLeft: const Radius.circular(14),
        topRight: const Radius.circular(14),
      ),
      topStrip,
    );

    // Obramowanie ścianki 1px
    final Paint borderPaint = Paint()
      ..color = AppTheme.borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(wallRect, borderPaint);

    // Delikatna siatka telemetryczna na ściance
    final Paint gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    const int cols = 8;
    for (int c = 1; c < cols; c++) {
      final double x = wallLeft + (wallW / cols) * c;
      canvas.drawLine(Offset(x, wallTop + 8), Offset(x, wallTop + wallH - 4), gridPaint);
    }

    // Napis nazwy wyścigu / ceremonii na ściance
    final TextPainter titlePainter = TextPainter(
      text: TextSpan(
        text: stageTitle.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          color: AppColors.goldAccent.withValues(alpha: 0.85),
          fontSize: (size.width * 0.022).clamp(10.0, 15.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: wallW - 24);
    titlePainter.paint(
      canvas,
      Offset(
        size.width * 0.5 - titlePainter.width * 0.5,
        wallTop + 14,
      ),
    );
  }

  void _paintWinnerFlagProjection(Canvas canvas, Size size) {
    final PodiumRiderEntry? winner = _riderForPosition(1);
    if (winner == null) return;

    final PodiumNationalAnthemProfile anthem =
        PodiumNationalAnthemProfile.forCountry(winner.nationalityCode);
    final double flagW = (size.width * 0.18).clamp(76.0, 148.0);
    final double flagH = flagW * 0.56;
    final double left = size.width * 0.5 - flagW * 0.5;
    final double top = size.height * 0.21;

    canvas.save();
    final RRect flagRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, flagW, flagH),
      const Radius.circular(6),
    );
    canvas.clipRRect(flagRRect);

    final int stripes = anthem.flagColors.length.clamp(1, 4);
    final double stripeH = flagH / stripes;
    for (int i = 0; i < stripes; i++) {
      final double wave = math.sin(ceremonyTime * 3.0 + i) * 1.5;
      canvas.drawRect(
        Rect.fromLTWH(left, top + i * stripeH + wave, flagW, stripeH + 2),
        Paint()..color = anthem.flagColors[i].withValues(alpha: 0.26),
      );
    }
    canvas.restore();

    canvas.drawRRect(
      flagRRect,
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _paintStageFloor(Canvas canvas, Size size) {
    final double horizonY = size.height * 0.62;
    final Path floorPath = Path()
      ..moveTo(size.width * 0.08, horizonY)
      ..lineTo(size.width * 0.92, horizonY)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final Paint floorPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF1B1F28),
          AppColors.surface,
          AppColors.background,
        ],
      ).createShader(Rect.fromLTWH(0, horizonY, size.width, size.height - horizonY));
    canvas.drawPath(floorPath, floorPaint);

    // Linia krawędzi sceny 3D
    canvas.drawLine(
      Offset(size.width * 0.08, horizonY),
      Offset(size.width * 0.92, horizonY),
      Paint()
        ..color = AppColors.goldAccent.withValues(alpha: 0.35)
        ..strokeWidth = 1.5,
    );
  }

  void _paintThreeStep3dPodium(Canvas canvas, Size size) {
    final double stageBaseY = size.height * 0.77;
    final double stepWidth = (size.width * 0.20).clamp(68.0, 168.0);
    final double gap = (size.width * 0.016).clamp(4.0, 14.0);
    final double depthDx = stepWidth * 0.14;
    final double depthDy = stepWidth * 0.11;

    // Kolejność rysowania 3D: najpierw boki (2 i 3), na końcu środek (1) dla poprawnej głębi
    final List<_PodiumStepSpec> specs = <_PodiumStepSpec>[
      _PodiumStepSpec(
        position: 2,
        centerX: size.width * 0.5 - stepWidth - gap,
        height: (size.height * 0.16).clamp(44.0, 108.0),
        trimColor: const Color(0xFFCBD5E1),
        delayOffset: 0.0,
      ),
      _PodiumStepSpec(
        position: 3,
        centerX: size.width * 0.5 + stepWidth + gap,
        height: (size.height * 0.12).clamp(34.0, 82.0),
        trimColor: const Color(0xFFB45309),
        delayOffset: 0.15,
      ),
      _PodiumStepSpec(
        position: 1,
        centerX: size.width * 0.5,
        height: (size.height * 0.22).clamp(62.0, 145.0),
        trimColor: AppColors.goldAccent,
        delayOffset: 0.28,
      ),
    ];

    for (final _PodiumStepSpec spec in specs) {
      final double localProgress =
          ((podiumRiseProgress - spec.delayOffset) / (1.0 - spec.delayOffset))
              .clamp(0.0, 1.0);
      final double eased = Curves.easeOutBack.transform(localProgress);
      final double currentH = spec.height * eased;
      final double left = spec.centerX - stepWidth * 0.5;
      final double top = stageBaseY - currentH;

      final bool isHighlighted =
          hoveredPosition == spec.position || selectedPosition == spec.position;

      // Cień rzutu pod stopniem
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(spec.centerX + 4, stageBaseY + 6),
          width: stepWidth * 1.12,
          height: 14,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.5),
      );

      if (currentH > 2) {
        // Górna płaszczyzna stopnia (perspektywa 3D)
        final Path topFace = Path()
          ..moveTo(left, top)
          ..lineTo(left + depthDx, top - depthDy)
          ..lineTo(left + stepWidth + depthDx, top - depthDy)
          ..lineTo(left + stepWidth, top)
          ..close();
        canvas.drawPath(
          topFace,
          Paint()
            ..color = isHighlighted
                ? AppColors.surfaceLight
                : const Color(0xFF282D3A),
        );

        // Prawa ściana boczna 3D
        final Path sideFace = Path()
          ..moveTo(left + stepWidth, top)
          ..lineTo(left + stepWidth + depthDx, top - depthDy)
          ..lineTo(left + stepWidth + depthDx, stageBaseY - depthDy)
          ..lineTo(left + stepWidth, stageBaseY)
          ..close();
        canvas.drawPath(
          sideFace,
          Paint()..color = const Color(0xFF12151C),
        );

        // Front stopnia
        final Rect frontRect = Rect.fromLTWH(left, top, stepWidth, currentH);
        canvas.drawRect(
          frontRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                isHighlighted ? AppColors.surfaceLight : AppColors.surface,
                const Color(0xFF14171E),
              ],
            ).createShader(frontRect),
        );

        // Złota/srebrna/brązowa listwa górna
        canvas.drawRect(
          Rect.fromLTWH(left, top, stepWidth, 4.5),
          Paint()..color = spec.trimColor,
        );

        // Obramowanie frontu
        canvas.drawRect(
          frontRect,
          Paint()
            ..color = isHighlighted ? spec.trimColor : AppTheme.borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = isHighlighted ? 1.8 : 1.0,
        );

        // Cyfra miejsca (1, 2, 3)
        final TextPainter rankPainter = TextPainter(
          text: TextSpan(
            text: '${spec.position}',
            style: TextStyle(
              fontFamily: 'Inter',
              color: spec.trimColor,
              fontSize: (currentH * 0.42).clamp(14.0, 42.0),
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        rankPainter.paint(
          canvas,
          Offset(
            spec.centerX - rankPainter.width * 0.5,
            top + (currentH - rankPainter.height) * 0.52,
          ),
        );
      }

      // Kolarz na stopniu podium
      final PodiumRiderEntry? rider = _riderForPosition(spec.position);
      if (rider != null && localProgress > 0.25) {
        final double riderAlpha = ((localProgress - 0.25) / 0.75).clamp(0.0, 1.0);
        final PodiumLeaderJerseyType effectiveJersey =
            (spec.position == 1 && highlightedJersey != null)
                ? highlightedJersey!
                : rider.jerseyType;
        _paintPodiumCyclist(
          canvas: canvas,
          footCenter: Offset(spec.centerX + depthDx * 0.35, top - depthDy * 0.45),
          scale: (size.height * 0.0021).clamp(0.65, 1.25),
          rider: rider,
          jersey: effectiveJersey,
          alpha: riderAlpha,
          isWinner: spec.position == 1,
          isHighlighted: isHighlighted,
        );
      }
    }
  }

  void _paintPodiumCyclist({
    required Canvas canvas,
    required Offset footCenter,
    required double scale,
    required PodiumRiderEntry rider,
    required PodiumLeaderJerseyType jersey,
    required double alpha,
    required bool isWinner,
    required bool isHighlighted,
  }) {
    canvas.save();
    canvas.translate(footCenter.dx, footCenter.dy);
    canvas.scale(scale);

    final double cheerWave = isWinner
        ? math.sin(ceremonyTime * 3.8) * 6.0
        : math.sin(ceremonyTime * 2.2 + rider.position) * 2.0;

    // Cień stóp na podium
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 1), width: 32, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.4 * alpha),
    );

    // Nogi i buty kolarskie
    final Paint legPaint = Paint()..color = const Color(0xFFD6A88A).withValues(alpha: alpha);
    final Paint shoePaint = Paint()..color = Colors.white.withValues(alpha: alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -34, 8, 30), const Radius.circular(4)),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(3, -34, 8, 30), const Radius.circular(4)),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-13, -6, 11, 6), const Radius.circular(3)),
      shoePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(2, -6, 11, 6), const Radius.circular(3)),
      shoePaint,
    );

    // Spodenki (Bib shorts)
    final Paint shortsPaint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: alpha);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-14, -52, 28, 22),
        const Radius.circular(6),
      ),
      shortsPaint,
    );

    // Tułów — Koszulka lidera (Żółta, Zielona, Grochy, Biała lub drużynowa)
    const Rect torsoRect = Rect.fromLTWH(-17, -90, 34, 42);
    final RRect torsoRRect = RRect.fromRectAndRadius(
      torsoRect,
      const Radius.circular(9),
    );

    final Color baseJerseyColor = jersey == PodiumLeaderJerseyType.stageWinner
        ? rider.teamColor
        : jersey.primaryColor;

    canvas.drawRRect(
      torsoRRect,
      Paint()..color = baseJerseyColor.withValues(alpha: alpha),
    );

    // Wzór charakterystyczny koszulki lidera
    canvas.save();
    canvas.clipRRect(torsoRRect);
    if (jersey == PodiumLeaderJerseyType.polkaDot) {
      // Czerwone grochy na białej koszulce KOM
      final Paint dotPaint = Paint()
        ..color = jersey.accentColor.withValues(alpha: alpha);
      const List<Offset> dots = <Offset>[
        Offset(-10, -82),
        Offset(2, -84),
        Offset(11, -78),
        Offset(-4, -71),
        Offset(8, -66),
        Offset(-11, -60),
        Offset(1, -56),
        Offset(12, -55),
      ];
      for (final Offset d in dots) {
        canvas.drawCircle(d, 4.0, dotPaint);
      }
    } else {
      // Pas piersiowy + suwak
      canvas.drawRect(
        const Rect.fromLTWH(-17, -74, 34, 8),
        Paint()..color = jersey.accentColor.withValues(alpha: 0.85 * alpha),
      );
      canvas.drawLine(
        const Offset(0, -90),
        const Offset(0, -48),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.25 * alpha)
          ..strokeWidth = 1.4,
      );
    }
    canvas.restore();

    if (isHighlighted || rider.isPlayerTeam) {
      canvas.drawRRect(
        torsoRRect,
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.9 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }

    // Ręce (zwycięzca wznosi ramiona z trofeum/bukietem!)
    final Paint armPaint = Paint()
      ..color = baseJerseyColor.withValues(alpha: alpha)
      ..strokeWidth = 7.5
      ..strokeCap = StrokeCap.round;

    if (isWinner) {
      canvas.drawLine(const Offset(-16, -84), Offset(-28, -112 + cheerWave), armPaint);
      canvas.drawLine(const Offset(16, -84), Offset(28, -112 - cheerWave), armPaint);
      // Złoty puchar w prawej dłoni
      canvas.drawCircle(
        Offset(28, -117 - cheerWave),
        5.5,
        Paint()..color = AppColors.goldAccent.withValues(alpha: alpha),
      );
    } else {
      canvas.drawLine(const Offset(-16, -84), Offset(-22, -58 + cheerWave * 0.4), armPaint);
      canvas.drawLine(const Offset(16, -84), Offset(22, -58 - cheerWave * 0.4), armPaint);
    }

    // Głowa, okulary i kask aerodynamiczny
    canvas.drawCircle(
      const Offset(0, -101),
      10,
      Paint()..color = const Color(0xFFD6A88A).withValues(alpha: alpha),
    );
    // Okulary kolarskie
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -104, 16, 5), const Radius.circular(2)),
      Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.85 * alpha),
    );
    // Kask
    final Path helmet = Path()
      ..addArc(const Rect.fromLTWH(-12, -115, 24, 18), math.pi, math.pi);
    canvas.drawPath(
      helmet,
      Paint()
        ..color = (isWinner ? AppColors.goldAccent : rider.teamColor)
            .withValues(alpha: alpha),
    );

    canvas.restore();
  }

  void _paintCrowdSilhouettes(Canvas canvas, Size size) {
    final Paint crowdPaint = Paint()
      ..color = const Color(0xFF0A0C10).withValues(alpha: 0.88);
    final double baseY = size.height;
    const int count = 24;
    for (int i = 0; i < count; i++) {
      final double x = (size.width / (count - 1)) * i;
      final double bounce = math.sin(ceremonyTime * 4.5 + i * 0.9) * 3.0;
      final double headR = (size.width * 0.011).clamp(5.0, 9.0);
      final double y = baseY - (i % 3) * 4.0 - 12.0 + bounce;
      canvas.drawCircle(Offset(x, y - headR * 1.4), headR, crowdPaint);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y + 6), width: headR * 2.6, height: 22),
          const Radius.circular(6),
        ),
        crowdPaint,
      );
    }
  }

  void _paintPhotographerFlashes(Canvas canvas, Size size) {
    // Deterministyczne błyski fleszy fotoreporterów na dole sceny
    const int flashSlots = 7;
    for (int i = 0; i < flashSlots; i++) {
      final double phase = (ceremonyTime * 2.7 + i * 0.618) % 1.0;
      final double burst = phase < 0.14 ? (1.0 - phase / 0.14) : 0.0;
      final double intensity = (burst + manualFlashBoost * 0.7).clamp(0.0, 1.0);
      if (intensity <= 0.02) continue;

      final double fx = size.width * (0.12 + 0.76 * ((i * 37 % 100) / 100.0));
      final double fy = size.height * (0.82 + (i % 2) * 0.06);
      final double radius = (22.0 + 28.0 * intensity).clamp(14.0, 56.0);

      final Paint glow = Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            Colors.white.withValues(alpha: 0.92 * intensity),
            AppColors.cyanAccent.withValues(alpha: 0.45 * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(fx, fy), radius: radius));
      canvas.drawCircle(Offset(fx, fy), radius, glow);

      // Krzyżowe promienie flesza
      final Paint rayPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * intensity)
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset(fx - radius * 0.85, fy), Offset(fx + radius * 0.85, fy), rayPaint);
      canvas.drawLine(Offset(fx, fy - radius * 0.85), Offset(fx, fy + radius * 0.85), rayPaint);
    }
  }

  void _paintRaceConfetti(Canvas canvas, Size size) {
    final List<Color> colors = raceTheme.confettiColors;
    const int particleCount = 72;

    for (int i = 0; i < particleCount; i++) {
      final double seedX = ((i * 73 + 19) % 100) / 100.0;
      final double speed = 0.18 + ((i * 29) % 10) * 0.022;
      final double fallProgress = (ceremonyTime * speed + (i * 0.071)) % 1.12;
      final double y = fallProgress * size.height - 16;
      final double sway = math.sin(ceremonyTime * 3.2 + i * 0.8) * 14.0;
      final double x = seedX * size.width + sway;
      final double tilt = ceremonyTime * 4.5 + i;
      final double w = 5.5 + (i % 3) * 2.0;
      final double h = (3.5 + (i % 2) * 2.0) * math.cos(tilt).abs().clamp(0.25, 1.0);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(tilt * 0.35);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: w, height: h),
        Paint()..color = colors[i % colors.length].withValues(alpha: 0.9),
      );
      canvas.restore();
    }
  }

  void _paintAnthemEqualizerRibbon(Canvas canvas, Size size) {
    const int barCount = 24;
    final double totalW = (size.width * 0.34).clamp(110.0, 260.0);
    final double startX = size.width * 0.5 - totalW * 0.5;
    final double baseY = size.height * 0.835;
    final double barW = (totalW / barCount) * 0.6;
    final double step = totalW / barCount;

    for (int i = 0; i < barCount; i++) {
      final double wave =
          0.35 + 0.65 * math.sin(ceremonyTime * 6.5 + i * 0.55).abs();
      final double barH = 3.0 + wave * 11.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(startX + i * step, baseY - barH, barW, barH),
          const Radius.circular(2),
        ),
        Paint()..color = AppColors.goldAccent.withValues(alpha: 0.72),
      );
    }
  }

  PodiumRiderEntry? _riderForPosition(int position) {
    for (final PodiumRiderEntry entry in podiumRiders) {
      if (entry.position == position) return entry;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant Podium3dCeremonyPainter oldDelegate) {
    return oldDelegate.ceremonyTime != ceremonyTime ||
        oldDelegate.podiumRiseProgress != podiumRiseProgress ||
        oldDelegate.raceTheme != raceTheme ||
        oldDelegate.highlightedJersey != highlightedJersey ||
        oldDelegate.hoveredPosition != hoveredPosition ||
        oldDelegate.selectedPosition != selectedPosition ||
        oldDelegate.showConfetti != showConfetti ||
        oldDelegate.showCameraFlashes != showCameraFlashes ||
        oldDelegate.isAnthemPlaying != isAnthemPlaying ||
        oldDelegate.manualFlashBoost != manualFlashBoost ||
        oldDelegate.podiumRiders != podiumRiders;
  }
}

class _PodiumStepSpec {
  final int position;
  final double centerX;
  final double height;
  final Color trimColor;
  final double delayOffset;

  const _PodiumStepSpec({
    required this.position,
    required this.centerX,
    required this.height,
    required this.trimColor,
    required this.delayOffset,
  });
}

/// Pełny, responsywny widget ceremonii podium 3D z panelem sterowania:
/// - przełączaniem 4 koszulek lidera (Żółta, Zielona, W Grochy, Biała),
/// - odtwarzaczem hymnu narodowego zwycięzcy (flaga, tytuł, play/pause, wyciszenie),
/// - wyzwalaczem fleszy fotoreporterów i powtórką animacji podium,
/// - pełną obsługą stanów hover/active/disabled/focus oraz układów 390x844, 1024x768 i 1600x900.
class Podium3dCeremonyWidget extends StatefulWidget {
  final List<PodiumRiderEntry> podiumRiders;
  final PodiumCeremonyRaceTheme raceTheme;
  final String stageTitle;
  final VoidCallback? onAnthemReplay;
  final ValueChanged<PodiumRiderEntry>? onRiderSelected;

  const Podium3dCeremonyWidget({
    super.key,
    required this.podiumRiders,
    this.raceTheme = PodiumCeremonyRaceTheme.tourDeFrance,
    this.stageTitle = 'Ceremonia Dekoracji Etapu',
    this.onAnthemReplay,
    this.onRiderSelected,
  });

  @override
  State<Podium3dCeremonyWidget> createState() => _Podium3dCeremonyWidgetState();
}

class _Podium3dCeremonyWidgetState extends State<Podium3dCeremonyWidget>
    with TickerProviderStateMixin {
  late final AnimationController _loopController;
  late final AnimationController _riseController;
  late final AnimationController _flashBurstController;

  PodiumLeaderJerseyType? _highlightedJersey;
  int? _hoveredPosition;
  int _selectedPosition = 1;
  bool _isAnthemPlaying = true;
  bool _isAnthemMuted = false;
  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _riseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();

    _flashBurstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _loopController.dispose();
    _riseController.dispose();
    _flashBurstController.dispose();
    super.dispose();
  }

  PodiumRiderEntry? get _winner {
    for (final PodiumRiderEntry r in widget.podiumRiders) {
      if (r.position == 1) return r;
    }
    return widget.podiumRiders.isNotEmpty ? widget.podiumRiders.first : null;
  }

  void _replayCeremony() {
    _riseController.forward(from: 0.0);
    _flashBurstController.forward(from: 0.0);
    widget.onAnthemReplay?.call();
  }

  void _triggerCameraFlashBurst() {
    _flashBurstController.forward(from: 0.0);
  }

  void _selectPosition(int pos) {
    setState(() => _selectedPosition = pos);
    for (final PodiumRiderEntry r in widget.podiumRiders) {
      if (r.position == pos) {
        widget.onRiderSelected?.call(r);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final PodiumRiderEntry? winner = _winner;
    final PodiumNationalAnthemProfile? anthem = winner != null
        ? PodiumNationalAnthemProfile.forCountry(winner.nationalityCode)
        : null;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 600;
        final double stageHeight = isCompact ? 240.0 : 320.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeaderBar(isCompact),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: stageHeight,
                  child: AnimatedBuilder(
                    animation: Listenable.merge(<Listenable>[
                      _loopController,
                      _riseController,
                      _flashBurstController,
                    ]),
                    builder: (BuildContext context, _) {
                      return CustomPaint(
                        painter: Podium3dCeremonyPainter(
                          podiumRiders: widget.podiumRiders,
                          ceremonyTime: _loopController.value * 12.0,
                          podiumRiseProgress: _riseController.value,
                          raceTheme: widget.raceTheme,
                          highlightedJersey: _highlightedJersey,
                          hoveredPosition: _hoveredPosition,
                          selectedPosition: _selectedPosition,
                          showConfetti: _showConfetti,
                          showCameraFlashes: true,
                          isAnthemPlaying: _isAnthemPlaying && !_isAnthemMuted,
                          manualFlashBoost: 1.0 - _flashBurstController.value,
                          stageTitle: widget.stageTitle,
                        ),
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildJerseySelectorRow(isCompact),
              const SizedBox(height: 12),
              if (anthem != null && winner != null) ...<Widget>[
                _buildAnthemBanner(anthem, winner, isCompact),
                const SizedBox(height: 12),
              ],
              _buildPodiumRidersStrip(isCompact),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderBar(bool isCompact) {
    final List<Widget> actionButtons = <Widget>[
      _CeremonyActionButton(
        icon: Icons.camera_alt_outlined,
        label: 'Flesze',
        isActive: false,
        onPressed: _triggerCameraFlashBurst,
      ),
      const SizedBox(width: 8),
      _CeremonyActionButton(
        icon: Icons.celebration_outlined,
        label: 'Konfetti',
        isActive: _showConfetti,
        onPressed: () => setState(() => _showConfetti = !_showConfetti),
      ),
      const SizedBox(width: 8),
      _CeremonyActionButton(
        icon: Icons.replay_rounded,
        label: 'Powtórz',
        isActive: false,
        onPressed: _replayCeremony,
      ),
    ];

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.stageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
        ],
      );
    }

    return Row(
      children: <Widget>[
        const Icon(Icons.emoji_events_rounded, color: AppColors.goldAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            widget.stageTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ),
        ...actionButtons,
      ],
    );
  }

  Widget _buildJerseySelectorRow(bool isCompact) {
    const List<PodiumLeaderJerseyType> jerseys = <PodiumLeaderJerseyType>[
      PodiumLeaderJerseyType.yellow,
      PodiumLeaderJerseyType.green,
      PodiumLeaderJerseyType.polkaDot,
      PodiumLeaderJerseyType.white,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: jerseys.map((PodiumLeaderJerseyType jersey) {
        final bool selected = _highlightedJersey == jersey;
        return _CeremonyActionButton(
          icon: Icons.checkroom_rounded,
          iconColor: jersey == PodiumLeaderJerseyType.polkaDot
              ? jersey.accentColor
              : jersey.primaryColor,
          label: jersey.label,
          isActive: selected,
          onPressed: () {
            setState(() {
              _highlightedJersey = selected ? null : jersey;
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAnthemBanner(
    PodiumNationalAnthemProfile anthem,
    PodiumRiderEntry winner,
    bool isCompact,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isAnthemPlaying
              ? AppColors.goldAccent.withValues(alpha: 0.55)
              : AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      child: Row(
        children: <Widget>[
          _MiniFlagBadge(colors: anthem.flagColors),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'HYMN ZWYCIĘZCY • ${anthem.countryName.toUpperCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${anthem.anthemTitle} (${winner.riderName})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CeremonyActionButton(
            icon: _isAnthemPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            label: isCompact ? '' : (_isAnthemPlaying ? 'Pauza' : 'Hymn'),
            isActive: _isAnthemPlaying,
            onPressed: () => setState(() => _isAnthemPlaying = !_isAnthemPlaying),
          ),
          const SizedBox(width: 6),
          _CeremonyActionButton(
            icon: _isAnthemMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            label: '',
            isActive: !_isAnthemMuted,
            isDisabled: !_isAnthemPlaying,
            onPressed: _isAnthemPlaying
                ? () => setState(() => _isAnthemMuted = !_isAnthemMuted)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPodiumRidersStrip(bool isCompact) {
    if (widget.podiumRiders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'Brak sklasyfikowanych kolarzy na podium etapu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      );
    }

    final List<PodiumRiderEntry> sorted = List<PodiumRiderEntry>.of(widget.podiumRiders)
      ..sort((PodiumRiderEntry a, PodiumRiderEntry b) => a.position.compareTo(b.position));

    if (isCompact) {
      return Column(
        children: sorted.map((PodiumRiderEntry entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRiderCard(entry),
          );
        }).toList(),
      );
    }

    return Row(
      children: sorted.map((PodiumRiderEntry entry) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: entry == sorted.last ? 0 : 10),
            child: _buildRiderCard(entry),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRiderCard(PodiumRiderEntry entry) {
    final bool isSelected = _selectedPosition == entry.position;
    final bool isHovered = _hoveredPosition == entry.position;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredPosition = entry.position),
      onExit: (_) => setState(() {
        if (_hoveredPosition == entry.position) _hoveredPosition = null;
      }),
      child: FocusableActionDetector(
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _selectPosition(entry.position);
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: () => _selectPosition(entry.position),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected || isHovered
                  ? AppColors.surfaceLight
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.goldAccent
                    : isHovered
                        ? AppColors.textSecondary
                        : AppTheme.borderColor,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: entry.position == 1
                        ? AppColors.goldAccent.withValues(alpha: 0.2)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.position}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: entry.position == 1
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entry.riderName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${entry.teamName} • ${entry.jerseyType.shortCode}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.timeOrGap,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.goldAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
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

class _MiniFlagBadge extends StatelessWidget {
  final List<Color> colors;

  const _MiniFlagBadge({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 22,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        children: colors.map((Color c) {
          return Expanded(child: Container(color: c));
        }).toList(),
      ),
    );
  }
}

class _CeremonyActionButton extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _CeremonyActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    this.iconColor,
    this.isDisabled = false,
    this.onPressed,
  });

  @override
  State<_CeremonyActionButton> createState() => _CeremonyActionButtonState();
}

class _CeremonyActionButtonState extends State<_CeremonyActionButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = !widget.isDisabled && widget.onPressed != null;
    final Color bg = !enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : _isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : widget.isActive
                ? AppColors.goldAccent.withValues(alpha: 0.16)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.background;

    final Color border = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.cyanAccent
            : widget.isActive
                ? AppColors.goldAccent
                : _isHovered
                    ? AppColors.textSecondary
                    : AppTheme.borderColor;

    final Color fg = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.isActive
            ? AppColors.goldAccent
            : AppColors.textPrimary;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: FocusableActionDetector(
        enabled: enabled,
        onShowFocusHighlight: (bool focused) => setState(() => _isFocused = focused),
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
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.label.isEmpty ? 8 : 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  widget.icon,
                  size: 16,
                  color: enabled ? (widget.iconColor ?? fg) : fg,
                ),
                if (widget.label.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
