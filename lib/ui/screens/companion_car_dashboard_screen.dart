import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../services/network/dual_screen_telemetry_wall_server.dart';

/// Identifier for the 3 virtual telemetry monitors on the Team Car console.
enum CompanionMonitorId {
  biometrics(
    code: 'MON-01',
    title: 'Biometria & Moc',
    shortLabel: 'MON-01 Biometria',
    icon: Icons.monitor_heart_outlined,
  ),
  tactics(
    code: 'MON-02',
    title: 'Taktyka & Luki',
    shortLabel: 'MON-02 Taktyka',
    icon: Icons.radar_outlined,
  ),
  radioAndService(
    code: 'MON-03',
    title: 'Radio & Serwis',
    shortLabel: 'MON-03 Radio',
    icon: Icons.headset_mic_outlined,
  );

  const CompanionMonitorId({
    required this.code,
    required this.title,
    required this.shortLabel,
    required this.icon,
  });

  final String code;
  final String title;
  final String shortLabel;
  final IconData icon;
}

/// Operating mode of the Team Car Companion Console.
enum CompanionConnectionMode {
  demoSimulation,
  websocketLive,
  disconnected,
}

/// Deterministic generator and local command processor for Demo / Offline mode
/// of [CompanionCarDashboardScreen].
class CompanionCarDemoTelemetryGenerator {
  CompanionCarDemoTelemetryGenerator._();

  static TelemetryWallFrame createInitialFrame() {
    return TelemetryWallFrame(
      sequence: 1,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      stageName: 'Etap 15: Alpe d\'Huez — Col du Galibier',
      kmCompleted: 112.4,
      totalKm: 178.5,
      pelotonSpeedKmh: 44.6,
      windSpeedKmh: 22.5,
      windDirectionDeg: 68.0,
      temperatureC: 27.4,
      weatherLabel: 'Słonecznie / Wiatr boczny',
      riders: const <CompanionRiderTelemetry>[
        CompanionRiderTelemetry(
          riderId: 'r_1',
          riderName: 'K. Majewski',
          bibNumber: 11,
          role: 'Lider GC',
          watts: 382,
          wPerKg: 5.97,
          heartRateBpm: 171,
          cadenceRpm: 92,
          wPrimePercent: 84.0,
          glycogenPercent: 72.0,
          coreTempC: 38.4,
          effortPercent: 86,
          tacticalOrder: 'Chroń Pozycję',
          gapToLeaderSec: 0.0,
          powerZone: 4,
          isLeader: true,
        ),
        CompanionRiderTelemetry(
          riderId: 'r_2',
          riderName: 'M. Kowalski',
          bibNumber: 12,
          role: 'Góral',
          watts: 368,
          wPerKg: 5.75,
          heartRateBpm: 176,
          cadenceRpm: 89,
          wPrimePercent: 68.0,
          glycogenPercent: 65.0,
          coreTempC: 38.7,
          effortPercent: 88,
          tacticalOrder: 'Chroń Lidera',
          gapToLeaderSec: 1.5,
          powerZone: 4,
        ),
        CompanionRiderTelemetry(
          riderId: 'r_3',
          riderName: 'L. Vermeulen',
          bibNumber: 13,
          role: 'Klasykowiec',
          watts: 395,
          wPerKg: 5.34,
          heartRateBpm: 169,
          cadenceRpm: 95,
          wPrimePercent: 76.0,
          glycogenPercent: 69.0,
          coreTempC: 38.2,
          effortPercent: 84,
          tacticalOrder: 'Nadawaj Tempo',
          gapToLeaderSec: 0.0,
          powerZone: 4,
        ),
        CompanionRiderTelemetry(
          riderId: 'r_4',
          riderName: 'A. Moreau',
          bibNumber: 14,
          role: 'Pomocnik',
          watts: 342,
          wPerKg: 4.89,
          heartRateBpm: 164,
          cadenceRpm: 90,
          wPrimePercent: 91.0,
          glycogenPercent: 78.0,
          coreTempC: 37.9,
          effortPercent: 76,
          tacticalOrder: 'Bidony dla Ekipy',
          gapToLeaderSec: 14.0,
          powerZone: 3,
        ),
        CompanionRiderTelemetry(
          riderId: 'r_5',
          riderName: 'P. Zieliński',
          bibNumber: 15,
          role: 'Uciekinier',
          watts: 412,
          wPerKg: 5.89,
          heartRateBpm: 181,
          cadenceRpm: 96,
          wPrimePercent: 42.0,
          glycogenPercent: 54.0,
          coreTempC: 39.0,
          effortPercent: 93,
          tacticalOrder: 'Ucieczka Dnia',
          gapToLeaderSec: -134.0,
          powerZone: 5,
        ),
        CompanionRiderTelemetry(
          riderId: 'r_6',
          riderName: 'T. Lindqvist',
          bibNumber: 16,
          role: 'Rozprowadzający',
          watts: 318,
          wPerKg: 4.30,
          heartRateBpm: 158,
          cadenceRpm: 88,
          wPrimePercent: 88.0,
          glycogenPercent: 81.0,
          coreTempC: 37.8,
          effortPercent: 72,
          tacticalOrder: 'Oszczędzaj Siły',
          gapToLeaderSec: 4.0,
          powerZone: 3,
        ),
        CompanionRiderTelemetry(
          riderId: 'r_7',
          riderName: 'J. Morales',
          bibNumber: 17,
          role: 'Góral',
          watts: 356,
          wPerKg: 5.84,
          heartRateBpm: 173,
          cadenceRpm: 91,
          wPrimePercent: 79.0,
          glycogenPercent: 70.0,
          coreTempC: 38.5,
          effortPercent: 82,
          tacticalOrder: 'Chroń Lidera',
          gapToLeaderSec: 2.0,
          powerZone: 4,
        ),
        CompanionRiderTelemetry(
          riderId: 'r_8',
          riderName: 'S. Conti',
          bibNumber: 18,
          role: 'Sprinter',
          watts: 265,
          wPerKg: 3.53,
          heartRateBpm: 146,
          cadenceRpm: 84,
          wPrimePercent: 96.0,
          glycogenPercent: 86.0,
          coreTempC: 37.6,
          effortPercent: 60,
          tacticalOrder: 'Grupetto',
          gapToLeaderSec: 270.0,
          powerZone: 2,
        ),
      ],
      groupGaps: const <CompanionGroupGap>[
        CompanionGroupGap(
          groupName: 'Ucieczka Dnia',
          gapSeconds: -134.0,
          riderCount: 6,
          teamRidersCount: 1,
        ),
        CompanionGroupGap(
          groupName: 'Grupa Pościgowa',
          gapSeconds: -48.0,
          riderCount: 4,
          teamRidersCount: 0,
        ),
        CompanionGroupGap(
          groupName: 'Peleton Główny',
          gapSeconds: 0.0,
          riderCount: 118,
          teamRidersCount: 6,
        ),
        CompanionGroupGap(
          groupName: 'Grupetto (Autobus)',
          gapSeconds: 270.0,
          riderCount: 42,
          teamRidersCount: 1,
        ),
      ],
      radioFeed: const <CompanionRadioEvent>[
        CompanionRadioEvent(
          id: 'rad_1',
          kmMark: 112.4,
          sender: 'Dyrektor Sportowy',
          message: 'Uwaga na boczny wiatr za 3 km — utrzymywać formację przy prawej krawędzi!',
          isUrgent: true,
        ),
        CompanionRadioEvent(
          id: 'rad_2',
          kmMark: 110.8,
          sender: 'Radio Tour',
          message: 'Przewaga ucieczki spada do 2:14. Peleton zwiększa tempo do 45 km/h.',
        ),
        CompanionRadioEvent(
          id: 'rad_3',
          kmMark: 108.5,
          sender: 'Mechanik Wozu #1',
          message: 'Rower zapasowy #11 gotowy na dachu. Ciśnienie 5.6 bar.',
        ),
      ],
      serviceStatus: const CompanionServiceStatus(
        teamCarGapSeconds: 18.5,
        barrageActive: false,
        bottlesRemaining: 34,
        gelsRemaining: 26,
        iceSocksRemaining: 10,
        spareBikesRemaining: 6,
      ),
    );
  }

  static TelemetryWallFrame advanceTick(TelemetryWallFrame current, int tickIndex) {
    final kmDelta = (current.pelotonSpeedKmh / 3600.0) * 1.5;
    final nextKm = math.min(current.totalKm, current.kmCompleted + kmDelta);
    final windWave = math.sin(tickIndex * 0.25) * 1.8;
    final speedWave = math.cos(tickIndex * 0.18) * 0.9;

    final updatedRiders = <CompanionRiderTelemetry>[];
    for (var i = 0; i < current.riders.length; i++) {
      final r = current.riders[i];
      final jitter = ((tickIndex + i * 3) % 5) - 2;
      final baseWatts = (r.effortPercent * 4.45).round();
      final nextWatts = math.max(150, baseWatts + jitter * 4);
      final weightApprox = r.wPerKg > 0.1 ? (r.watts / r.wPerKg) : 68.0;
      final nextWPerKg = double.parse((nextWatts / weightApprox).toStringAsFixed(2));
      final nextHr = (r.heartRateBpm + (jitter > 0 ? 1 : (jitter < 0 ? -1 : 0))).clamp(120, 196);
      final nextCadence = (r.cadenceRpm + (jitter % 2)).clamp(70, 112);

      final wPrimeDelta = r.effortPercent >= 90 ? -0.45 : (r.effortPercent <= 75 ? 0.35 : 0.05);
      final nextWPrime = (r.wPrimePercent + wPrimeDelta).clamp(5.0, 100.0);
      final nextGlycogen = (r.glycogenPercent - 0.03).clamp(10.0, 100.0);
      final nextZone = _zoneFromEffort(r.effortPercent);

      updatedRiders.add(
        CompanionRiderTelemetry(
          riderId: r.riderId,
          riderName: r.riderName,
          bibNumber: r.bibNumber,
          role: r.role,
          watts: nextWatts,
          wPerKg: nextWPerKg,
          heartRateBpm: nextHr,
          cadenceRpm: nextCadence,
          wPrimePercent: double.parse(nextWPrime.toStringAsFixed(1)),
          glycogenPercent: double.parse(nextGlycogen.toStringAsFixed(1)),
          coreTempC: r.coreTempC,
          effortPercent: r.effortPercent,
          tacticalOrder: r.tacticalOrder,
          gapToLeaderSec: r.gapToLeaderSec,
          powerZone: nextZone,
          isLeader: r.isLeader,
        ),
      );
    }

    final updatedGaps = current.groupGaps.map((g) {
      if (g.groupName == 'Peleton Główny') return g;
      final shift = g.gapSeconds < 0 ? 0.4 : 0.6;
      final nextGap = (g.gapSeconds + shift).clamp(-300.0, 600.0);
      return CompanionGroupGap(
        groupName: g.groupName,
        gapSeconds: double.parse(nextGap.toStringAsFixed(1)),
        riderCount: g.riderCount,
        teamRidersCount: g.teamRidersCount,
      );
    }).toList(growable: false);

    return TelemetryWallFrame(
      sequence: current.sequence + 1,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      stageName: current.stageName,
      kmCompleted: double.parse(nextKm.toStringAsFixed(1)),
      totalKm: current.totalKm,
      pelotonSpeedKmh: double.parse((44.6 + speedWave).clamp(32.0, 58.0).toStringAsFixed(1)),
      windSpeedKmh: double.parse((22.5 + windWave).clamp(5.0, 65.0).toStringAsFixed(1)),
      windDirectionDeg: current.windDirectionDeg,
      temperatureC: current.temperatureC,
      weatherLabel: current.weatherLabel,
      riders: updatedRiders,
      groupGaps: updatedGaps,
      radioFeed: current.radioFeed,
      serviceStatus: current.serviceStatus,
    );
  }

  static TelemetryWallFrame applyCommand(
    TelemetryWallFrame current,
    CompanionCarCommand command,
  ) {
    var riders = List<CompanionRiderTelemetry>.from(current.riders);
    var service = current.serviceStatus;
    var radioFeed = List<CompanionRadioEvent>.from(current.radioFeed);

    String? radioMessage;
    bool urgent = false;

    switch (command.type) {
      case CompanionCommandType.setEffort:
        final targetEffort = (command.effortPercent ?? 75).clamp(30, 100);
        riders = riders.map((r) {
          if (r.riderId != command.riderId) return r;
          final weightApprox = r.wPerKg > 0.1 ? (r.watts / r.wPerKg) : 68.0;
          final nextWatts = (targetEffort * 4.45).round();
          return CompanionRiderTelemetry(
            riderId: r.riderId,
            riderName: r.riderName,
            bibNumber: r.bibNumber,
            role: r.role,
            watts: nextWatts,
            wPerKg: double.parse((nextWatts / weightApprox).toStringAsFixed(2)),
            heartRateBpm: r.heartRateBpm,
            cadenceRpm: r.cadenceRpm,
            wPrimePercent: r.wPrimePercent,
            glycogenPercent: r.glycogenPercent,
            coreTempC: r.coreTempC,
            effortPercent: targetEffort,
            tacticalOrder: r.tacticalOrder,
            gapToLeaderSec: r.gapToLeaderSec,
            powerZone: _zoneFromEffort(targetEffort),
            isLeader: r.isLeader,
          );
        }).toList(growable: false);
        radioMessage = 'Zmiana wysiłku kolarza na $targetEffort%.';
        break;
      case CompanionCommandType.tacticalOrder:
        final order = command.orderName ?? 'Utrzymuj Pozycję';
        riders = riders.map((r) {
          if (r.riderId != command.riderId) return r;
          return CompanionRiderTelemetry(
            riderId: r.riderId,
            riderName: r.riderName,
            bibNumber: r.bibNumber,
            role: r.role,
            watts: r.watts,
            wPerKg: r.wPerKg,
            heartRateBpm: r.heartRateBpm,
            cadenceRpm: r.cadenceRpm,
            wPrimePercent: r.wPrimePercent,
            glycogenPercent: r.glycogenPercent,
            coreTempC: r.coreTempC,
            effortPercent: r.effortPercent,
            tacticalOrder: order,
            gapToLeaderSec: r.gapToLeaderSec,
            powerZone: r.powerZone,
            isLeader: r.isLeader,
          );
        }).toList(growable: false);
        radioMessage = 'Rozkaz indywidualny: "$order".';
        break;
      case CompanionCommandType.teamPreset:
        final preset = command.presetName ?? 'Ochrona Lidera';
        final presetEffort = switch (preset) {
          'Oszczędzaj Siły' => 65,
          'Pociąg na Czele' => 90,
          'Wachlarz (Echelon)' => 88,
          'Pełny Atak' => 96,
          _ => 80,
        };
        riders = riders.map((r) {
          final weightApprox = r.wPerKg > 0.1 ? (r.watts / r.wPerKg) : 68.0;
          final nextWatts = (presetEffort * 4.45).round();
          return CompanionRiderTelemetry(
            riderId: r.riderId,
            riderName: r.riderName,
            bibNumber: r.bibNumber,
            role: r.role,
            watts: nextWatts,
            wPerKg: double.parse((nextWatts / weightApprox).toStringAsFixed(2)),
            heartRateBpm: r.heartRateBpm,
            cadenceRpm: r.cadenceRpm,
            wPrimePercent: r.wPrimePercent,
            glycogenPercent: r.glycogenPercent,
            coreTempC: r.coreTempC,
            effortPercent: presetEffort,
            tacticalOrder: preset,
            gapToLeaderSec: r.gapToLeaderSec,
            powerZone: _zoneFromEffort(presetEffort),
            isLeader: r.isLeader,
          );
        }).toList(growable: false);
        radioMessage = 'Preset drużynowy aktywowany: $preset.';
        urgent = preset == 'Pełny Atak' || preset == 'Wachlarz (Echelon)';
        break;
      case CompanionCommandType.serviceRequest:
        final sType = command.serviceType ?? 'bottles';
        if (sType == 'bottles' && service.bottlesRemaining > 0) {
          service = CompanionServiceStatus(
            teamCarGapSeconds: service.teamCarGapSeconds,
            barrageActive: service.barrageActive,
            bottlesRemaining: service.bottlesRemaining - 1,
            gelsRemaining: service.gelsRemaining,
            iceSocksRemaining: service.iceSocksRemaining,
            spareBikesRemaining: service.spareBikesRemaining,
          );
          radioMessage = 'Wysłano bidony z wozu technicznego #1.';
        } else if (sType == 'gels' && service.gelsRemaining > 0) {
          service = CompanionServiceStatus(
            teamCarGapSeconds: service.teamCarGapSeconds,
            barrageActive: service.barrageActive,
            bottlesRemaining: service.bottlesRemaining,
            gelsRemaining: service.gelsRemaining - 1,
            iceSocksRemaining: service.iceSocksRemaining,
            spareBikesRemaining: service.spareBikesRemaining,
          );
          radioMessage = 'Wysłano żele energetyczne do peletonu.';
        } else if (sType == 'ice' && service.iceSocksRemaining > 0) {
          service = CompanionServiceStatus(
            teamCarGapSeconds: service.teamCarGapSeconds,
            barrageActive: service.barrageActive,
            bottlesRemaining: service.bottlesRemaining,
            gelsRemaining: service.gelsRemaining,
            iceSocksRemaining: service.iceSocksRemaining - 1,
            spareBikesRemaining: service.spareBikesRemaining,
          );
          radioMessage = 'Wysłano woreczek z lodem (Ice Sock).';
        } else if (sType == 'bike' && service.spareBikesRemaining > 0) {
          service = CompanionServiceStatus(
            teamCarGapSeconds: service.teamCarGapSeconds,
            barrageActive: service.barrageActive,
            bottlesRemaining: service.bottlesRemaining,
            gelsRemaining: service.gelsRemaining,
            iceSocksRemaining: service.iceSocksRemaining,
            spareBikesRemaining: service.spareBikesRemaining - 1,
          );
          radioMessage = 'Wóz techniczny podjeżdża z rowerem zapasowym!';
          urgent = true;
        } else if (sType == 'barrage_toggle') {
          service = CompanionServiceStatus(
            teamCarGapSeconds: service.teamCarGapSeconds,
            barrageActive: !service.barrageActive,
            bottlesRemaining: service.bottlesRemaining,
            gelsRemaining: service.gelsRemaining,
            iceSocksRemaining: service.iceSocksRemaining,
            spareBikesRemaining: service.spareBikesRemaining,
          );
          radioMessage = service.barrageActive
              ? 'Sędzia UCI wprowadził BARRAGE za peletonem.'
              : 'Sędzia UCI otworzył konwój serwisowy.';
          urgent = service.barrageActive;
        }
        break;
      case CompanionCommandType.ping:
        radioMessage = 'Test łączności radiowej Wóz <-> Peleton: OK (12 ms).';
        break;
    }

    if (radioMessage != null) {
      radioFeed = <CompanionRadioEvent>[
        CompanionRadioEvent(
          id: 'cmd_${command.commandId}',
          kmMark: current.kmCompleted,
          sender: 'Konsola DS',
          message: radioMessage,
          isUrgent: urgent,
        ),
        ...radioFeed,
      ].take(18).toList(growable: false);
    }

    return TelemetryWallFrame(
      sequence: current.sequence + 1,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      stageName: current.stageName,
      kmCompleted: current.kmCompleted,
      totalKm: current.totalKm,
      pelotonSpeedKmh: current.pelotonSpeedKmh,
      windSpeedKmh: current.windSpeedKmh,
      windDirectionDeg: current.windDirectionDeg,
      temperatureC: current.temperatureC,
      weatherLabel: current.weatherLabel,
      riders: riders,
      groupGaps: current.groupGaps,
      radioFeed: radioFeed,
      serviceStatus: service,
    );
  }

  static int _zoneFromEffort(int effort) {
    if (effort < 55) return 1;
    if (effort < 70) return 2;
    if (effort < 82) return 3;
    if (effort < 90) return 4;
    if (effort < 95) return 5;
    if (effort < 99) return 6;
    return 7;
  }
}

/// CustomPainter rendering the tactical gap radar across race groups and Team Car #1.
class CompanionPelotonRadarPainter extends CustomPainter {
  const CompanionPelotonRadarPainter({
    required this.groups,
    required this.teamCarGapSeconds,
    required this.barrageActive,
  });

  final List<CompanionGroupGap> groups;
  final double teamCarGapSeconds;
  final bool barrageActive;

  @override
  void paint(Canvas canvas, Size size) {
    final trackY = size.height * 0.56;
    const padX = 20.0;
    final trackWidth = math.max(40.0, size.width - padX * 2);

    // Background grid lines
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1.0;
    for (var i = 0; i <= 4; i++) {
      final x = padX + (trackWidth / 4) * i;
      canvas.drawLine(Offset(x, 12), Offset(x, size.height - 12), gridPaint);
    }

    // Road axis
    final roadPaint = Paint()
      ..color = const Color(0xFF2A2F3D)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(padX, trackY), Offset(padX + trackWidth, trackY), roadPaint);

    // Direction arrow (right = front of race)
    final frontX = padX + trackWidth;
    final arrowPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final arrowPath = Path()
      ..moveTo(frontX - 8, trackY - 5)
      ..lineTo(frontX, trackY)
      ..lineTo(frontX - 8, trackY + 5);
    canvas.drawPath(arrowPath, arrowPaint);

    // Map gapSeconds [-240..+320] onto [0..1] where -240 is right (front) and +320 is left (rear)
    double mapGapToX(double gapSec) {
      final normalized = (1.0 - ((gapSec + 200.0) / 520.0)).clamp(0.06, 0.94);
      return padX + normalized * trackWidth;
    }

    // Team Car #1 marker behind peloton
    final carX = mapGapToX(teamCarGapSeconds);
    final carPaint = Paint()
      ..color = barrageActive ? AppColors.crimsonAlert : AppColors.primaryAccent;
    final carRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(carX, trackY + 18), width: 22, height: 10),
      const Radius.circular(3),
    );
    canvas.drawRRect(carRect, carPaint);

    final carLabelPainter = TextPainter(
      text: TextSpan(
        text: barrageActive ? 'WÓZ (BARRAGE)' : 'WÓZ #1',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: barrageActive ? AppColors.crimsonAlert : AppColors.textSecondary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    carLabelPainter.paint(
      canvas,
      Offset((carX - carLabelPainter.width / 2).clamp(4.0, size.width - carLabelPainter.width - 4), trackY + 26),
    );

    // Group nodes
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      final gx = mapGapToX(g.gapSeconds);
      final isPeloton = g.gapSeconds.abs() < 1.0;
      final color = g.gapSeconds < 0
          ? AppColors.accentBlue
          : (isPeloton ? AppColors.goldAccent : AppColors.textSecondary);

      final radius = isPeloton ? 9.0 : (g.teamRidersCount > 0 ? 7.5 : 5.5);
      canvas.drawCircle(
        Offset(gx, trackY),
        radius + 4,
        Paint()..color = color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(Offset(gx, trackY), radius, Paint()..color = color);

      final label = g.teamRidersCount > 0
          ? '${g.groupName.split(' ').first} (${g.teamRidersCount})'
          : g.groupName.split(' ').first;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final labelY = i.isEven ? trackY - 26 : trackY - 38;
      tp.paint(
        canvas,
        Offset((gx - tp.width / 2).clamp(4.0, size.width - tp.width - 4), labelY),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CompanionPelotonRadarPainter oldDelegate) {
    return oldDelegate.groups != groups ||
        oldDelegate.teamCarGapSeconds != teamCarGapSeconds ||
        oldDelegate.barrageActive != barrageActive;
  }
}

/// CustomPainter rendering a compact wind direction compass & crosswind risk indicator.
class CompanionWindCompassPainter extends CustomPainter {
  const CompanionWindCompassPainter({
    required this.windDirectionDeg,
    required this.windSpeedKmh,
  });

  final double windDirectionDeg;
  final double windSpeedKmh;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.surfaceLight
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF2A2F3D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final angleRad = (windDirectionDeg - 90) * math.pi / 180.0;
    final tip = Offset(
      center.dx + math.cos(angleRad) * (radius * 0.72),
      center.dy + math.sin(angleRad) * (radius * 0.72),
    );
    final tail = Offset(
      center.dx - math.cos(angleRad) * (radius * 0.45),
      center.dy - math.sin(angleRad) * (radius * 0.45),
    );

    final isCrosswindHigh = windSpeedKmh >= 20.0;
    final arrowColor = isCrosswindHigh ? AppColors.amberWarning : AppColors.cyanAccent;

    canvas.drawLine(
      tail,
      tip,
      Paint()
        ..color = arrowColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(tip, 3.5, Paint()..color = arrowColor);
  }

  @override
  bool shouldRepaint(covariant CompanionWindCompassPainter oldDelegate) {
    return oldDelegate.windDirectionDeg != windDirectionDeg ||
        oldDelegate.windSpeedKmh != windSpeedKmh;
  }
}

/// Production Team Car Telemetry Console with 3 virtual telemetry monitors.
/// Supports both live WebSocket connection to [DualScreenTelemetryWallServer]
/// via [DualScreenTelemetryWallClient] and built-in offline/demo simulation.
class CompanionCarDashboardScreen extends ConsumerStatefulWidget {
  const CompanionCarDashboardScreen({
    super.key,
    this.initialFrame,
    this.enableLiveTicker = true,
    this.onBackPressed,
  });

  final TelemetryWallFrame? initialFrame;
  final bool enableLiveTicker;
  final VoidCallback? onBackPressed;

  @override
  ConsumerState<CompanionCarDashboardScreen> createState() =>
      _CompanionCarDashboardScreenState();
}

class _CompanionCarDashboardScreenState
    extends ConsumerState<CompanionCarDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TelemetryWallFrame _frame;
  CompanionMonitorId _activeMobileMonitor = CompanionMonitorId.biometrics;
  CompanionConnectionMode _connectionMode = CompanionConnectionMode.demoSimulation;
  bool _isPaused = false;
  String? _selectedRiderId;
  int _tickCounter = 0;

  Timer? _demoTimer;
  DualScreenTelemetryWallClient? _wsClient;
  StreamSubscription<TelemetryWallFrame>? _wsFrameSub;
  StreamSubscription<Map<String, dynamic>>? _wsAckSub;
  late final AnimationController _pulseController;

  final TextEditingController _hostController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portController = TextEditingController(text: '8765');
  final TextEditingController _pinController = TextEditingController(text: '');
  String? _connectionError;
  bool _isConnecting = false;
  final List<String> _dispatchedCommandLog = <String>[];

  @override
  void initState() {
    super.initState();
    _frame = widget.initialFrame ?? CompanionCarDemoTelemetryGenerator.createInitialFrame();
    if (_frame.riders.isNotEmpty) {
      _selectedRiderId = _frame.riders.first.riderId;
    }
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    if (widget.enableLiveTicker) {
      _startDemoTicker();
    }
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _wsFrameSub?.cancel();
    _wsAckSub?.cancel();
    unawaited(_wsClient?.dispose());
    _pulseController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startDemoTicker() {
    _demoTimer?.cancel();
    _demoTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (!mounted || _isPaused || _connectionMode != CompanionConnectionMode.demoSimulation) {
        return;
      }
      setState(() {
        _tickCounter++;
        _frame = CompanionCarDemoTelemetryGenerator.advanceTick(_frame, _tickCounter);
      });
    });
  }

  Future<void> _connectWebSocket() async {
    final host = _hostController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 8765;
    final pin = _pinController.text.trim();
    if (host.isEmpty) {
      setState(() => _connectionError = 'Podaj adres IP lub nazwę hosta.');
      return;
    }

    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      await _wsFrameSub?.cancel();
      await _wsAckSub?.cancel();
      await _wsClient?.dispose();

      final client = DualScreenTelemetryWallClient();
      await client.connect(
        host: host,
        port: port,
        pin: pin,
        deviceName: 'Konsola Wozu #1',
        platform: 'Flutter',
      );

      _wsClient = client;
      _wsFrameSub = client.frameStream.listen((incomingFrame) {
        if (!mounted) return;
        setState(() {
          _frame = incomingFrame;
          if (_selectedRiderId == null && incomingFrame.riders.isNotEmpty) {
            _selectedRiderId = incomingFrame.riders.first.riderId;
          }
        });
      });
      _wsAckSub = client.ackStream.listen((ack) {
        if (!mounted) return;
        final type = ack['type'] as String? ?? '';
        if (type == 'auth_failed') {
          setState(() {
            _connectionError = 'Błędny kod PIN parowania.';
            _connectionMode = CompanionConnectionMode.disconnected;
          });
        }
      });

      if (!mounted) return;
      setState(() {
        _connectionMode = CompanionConnectionMode.websocketLive;
        _isConnecting = false;
        _connectionError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        _connectionError = 'Nie udało się połączyć: $e';
      });
    }
  }

  Future<void> _switchToDemoMode() async {
    await _wsFrameSub?.cancel();
    await _wsAckSub?.cancel();
    await _wsClient?.dispose();
    _wsClient = null;
    if (!mounted) return;
    setState(() {
      _connectionMode = CompanionConnectionMode.demoSimulation;
      _connectionError = null;
    });
    if (widget.enableLiveTicker) {
      _startDemoTicker();
    }
  }

  void _dispatchCommand(CompanionCarCommand command) {
    final nowLabel = _formatClock(DateTime.now());
    final summary = switch (command.type) {
      CompanionCommandType.setEffort =>
        '[$nowLabel] Wysiłek #${command.riderId ?? '-'} -> ${command.effortPercent}%',
      CompanionCommandType.tacticalOrder =>
        '[$nowLabel] Rozkaz #${command.riderId ?? '-'}: ${command.orderName}',
      CompanionCommandType.teamPreset => '[$nowLabel] Preset: ${command.presetName}',
      CompanionCommandType.serviceRequest => '[$nowLabel] Serwis: ${command.serviceType}',
      CompanionCommandType.ping => '[$nowLabel] Ping Wóz <-> Host',
    };

    if (_connectionMode == CompanionConnectionMode.websocketLive &&
        _wsClient != null &&
        _wsClient!.isConnected) {
      try {
        _wsClient!.sendCommand(command);
        setState(() {
          _dispatchedCommandLog.insert(0, summary);
          if (_dispatchedCommandLog.length > 10) _dispatchedCommandLog.removeLast();
        });
        return;
      } catch (e) {
        setState(() => _connectionError = 'Błąd wysyłki komendy: $e');
      }
    }

    setState(() {
      _frame = CompanionCarDemoTelemetryGenerator.applyCommand(_frame, command);
      _dispatchedCommandLog.insert(0, summary);
      if (_dispatchedCommandLog.length > 10) _dispatchedCommandLog.removeLast();
    });
  }

  void _openConnectionDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A2F3D)),
          ),
          title: const Text(
            'Połączenie LAN z Wozem Technicznym',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Połącz tablet lub drugi ekran z serwerem WebSocket gry (PC/Mac) lub pozostań w lokalnym trybie symulacji.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hostController,
                  style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, fontSize: 13),
                  decoration: _inputDecoration('Adres IP hosta (np. 192.168.1.24)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _portController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, fontSize: 13),
                        decoration: _inputDecoration('Port (8765)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _pinController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontFamily: 'Inter', color: AppColors.textPrimary, fontSize: 13),
                        decoration: _inputDecoration('Kod PIN'),
                      ),
                    ),
                  ],
                ),
                if (_connectionError != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(
                    _connectionError!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                unawaited(_switchToDemoMode());
              },
              child: const Text(
                'Tryb Demo',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: _isConnecting
                  ? null
                  : () async {
                      Navigator.of(ctx).pop();
                      await _connectWebSocket();
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                foregroundColor: AppColors.textPrimary,
              ),
              child: const Text('Połącz WebSocket', style: TextStyle(fontFamily: 'Inter')),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.surfaceLight,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF2A2F3D)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 720;
            final isDesktop3Col = width >= 1180;

            return Column(
              children: <Widget>[
                _buildTopCommandBar(isMobile: isMobile),
                if (isMobile) _buildMobileMonitorTabs(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 10 : 16,
                      8,
                      isMobile ? 10 : 16,
                      isMobile ? 10 : 16,
                    ),
                    child: isDesktop3Col
                        ? _buildDesktopThreeMonitorWall()
                        : (isMobile
                            ? _buildMobileSingleMonitorView()
                            : _buildTabletTwoPlusOneWall()),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopCommandBar({required bool isMobile}) {
    final progress = _frame.totalKm > 0
        ? (_frame.kmCompleted / _frame.totalKm).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: EdgeInsets.fromLTRB(isMobile ? 10 : 16, isMobile ? 8 : 12, isMobile ? 10 : 16, 4),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (widget.onBackPressed != null || Navigator.of(context).canPop())
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ConsoleInteractiveButton(
                    tooltip: 'Powrót',
                    onPressed: widget.onBackPressed ?? () => Navigator.of(context).maybePop(),
                    child: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryAccent),
                ),
                child: const Text(
                  'WÓZ #1 • DS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 210 : 320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _frame.stageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              '${_frame.kmCompleted.toStringAsFixed(1)} / ${_frame.totalKm.toStringAsFixed(1)} km',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.goldAccent,
                                fontWeight: FontWeight.w600,
                                fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: isMobile ? 42 : 64,
                            height: 4,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.surfaceLight,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _TelemetryHeaderChip(
                icon: Icons.speed_rounded,
                label: '${_frame.pelotonSpeedKmh.toStringAsFixed(1)} km/h',
                color: AppColors.accentBlue,
              ),
              _TelemetryHeaderChip(
                icon: Icons.air_rounded,
                label: '${_frame.windSpeedKmh.toStringAsFixed(0)} km/h',
                color: _frame.windSpeedKmh >= 20 ? AppColors.amberWarning : AppColors.textSecondary,
              ),
              _TelemetryHeaderChip(
                icon: Icons.thermostat_rounded,
                label: '${_frame.temperatureC.toStringAsFixed(1)}°C',
                color: _frame.temperatureC >= 28 ? AppColors.amberWarning : AppColors.textSecondary,
              ),
              _buildConnectionPill(),
              _ConsoleInteractiveButton(
                tooltip: _isPaused ? 'Wznów telemetrię' : 'Pauza telemetrii',
                isActive: _isPaused,
                onPressed: () => setState(() => _isPaused = !_isPaused),
                child: Icon(
                  _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  size: 18,
                  color: _isPaused ? AppColors.goldAccent : AppColors.textPrimary,
                ),
              ),
              _ConsoleInteractiveButton(
                tooltip: 'Połączenie LAN / WebSocket',
                onPressed: _openConnectionDialog,
                child: const Icon(Icons.wifi_tethering_rounded, size: 18, color: AppColors.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionPill() {
    final isLive = _connectionMode == CompanionConnectionMode.websocketLive;
    final isDemo = _connectionMode == CompanionConnectionMode.demoSimulation;
    final color = isLive
        ? AppColors.statusSuccess
        : (isDemo ? AppColors.accentBlue : AppColors.crimsonAlert);
    final label = isLive ? 'WS LIVE' : (isDemo ? 'DEMO LIVE' : 'OFFLINE');

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final alpha = 0.45 + (_pulseController.value * 0.55);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.55)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: _isPaused ? 0.35 : alpha),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileMonitorTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        children: CompanionMonitorId.values.map((monitor) {
          final selected = _activeMobileMonitor == monitor;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _ConsoleInteractiveButton(
                isActive: selected,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                onPressed: () => setState(() => _activeMobileMonitor = monitor),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      monitor.icon,
                      size: 14,
                      color: selected ? AppColors.goldAccent : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        monitor.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildDesktopThreeMonitorWall() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: 12, child: _buildMonitor1Biometrics()),
        const SizedBox(width: 12),
        Expanded(flex: 10, child: _buildMonitor2Tactics()),
        const SizedBox(width: 12),
        Expanded(flex: 10, child: _buildMonitor3RadioAndService()),
      ],
    );
  }

  Widget _buildTabletTwoPlusOneWall() {
    return Column(
      children: <Widget>[
        Expanded(
          flex: 11,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(flex: 11, child: _buildMonitor1Biometrics()),
              const SizedBox(width: 12),
              Expanded(flex: 9, child: _buildMonitor2Tactics()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(flex: 8, child: _buildMonitor3RadioAndService()),
      ],
    );
  }

  Widget _buildMobileSingleMonitorView() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      child: KeyedSubtree(
        key: ValueKey<CompanionMonitorId>(_activeMobileMonitor),
        child: switch (_activeMobileMonitor) {
          CompanionMonitorId.biometrics => _buildMonitor1Biometrics(),
          CompanionMonitorId.tactics => _buildMonitor2Tactics(),
          CompanionMonitorId.radioAndService => _buildMonitor3RadioAndService(),
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONITOR 1: Biometria & Moc Drużyny
  // ---------------------------------------------------------------------------
  Widget _buildMonitor1Biometrics() {
    final riders = _frame.riders;
    final avgWatts = riders.isEmpty
        ? 0
        : (riders.fold<int>(0, (sum, r) => sum + r.watts) / riders.length).round();
    final redZoneCount = riders.where((r) => r.wPrimePercent < 30 || r.coreTempC >= 38.9).length;

    CompanionRiderTelemetry? selectedRider;
    if (riders.isNotEmpty) {
      selectedRider = riders.firstWhere(
        (r) => r.riderId == _selectedRiderId,
        orElse: () => riders.first,
      );
    }

    return _MonitorFrame(
      monitor: CompanionMonitorId.biometrics,
      subtitle: 'Śr. $avgWatts W • Zagrożeni: $redZoneCount',
      accentColor: AppColors.accentBlue,
      child: Column(
        children: <Widget>[
          Expanded(
            child: riders.isEmpty
                ? const Center(
                    child: Text(
                      'Brak danych telemetrycznych kolarzy.',
                      style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: riders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final rider = riders[index];
                      final isSelected = selectedRider?.riderId == rider.riderId;
                      return _RiderTelemetryTile(
                        rider: rider,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedRiderId = rider.riderId),
                      );
                    },
                  ),
          ),
          if (selectedRider != null) ...<Widget>[
            const SizedBox(height: 10),
            _buildSelectedRiderControlDeck(selectedRider),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedRiderControlDeck(CompanionRiderTelemetry rider) {
    const quickOrders = <String>[
      'Chroń Lidera',
      'Nadawaj Tempo',
      'Oszczędzaj Siły',
      'Atakuj',
      'Czekaj na Wóz',
    ];

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rider.isLeader ? AppColors.goldAccent.withValues(alpha: 0.6) : const Color(0xFF2A2F3D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '#${rider.bibNumber} ${rider.riderName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Wysiłek: ${rider.effortPercent}%',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.getPowerZoneColor(rider.powerZone),
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              _ConsoleInteractiveButton(
                tooltip: 'Zmniejsz wysiłek -5%',
                enabled: rider.effortPercent > 30,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                onPressed: () {
                  final next = (rider.effortPercent - 5).clamp(30, 100);
                  _dispatchCommand(
                    CompanionCarCommand(
                      commandId: '${DateTime.now().millisecondsSinceEpoch}',
                      type: CompanionCommandType.setEffort,
                      clientId: 'console_ds',
                      issuedAtMs: DateTime.now().millisecondsSinceEpoch,
                      riderId: rider.riderId,
                      effortPercent: next,
                    ),
                  );
                },
                child: const Text(
                  '-5%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.getPowerZoneColor(rider.powerZone),
                    inactiveTrackColor: AppColors.background,
                    thumbColor: AppColors.goldAccent,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                  ),
                  child: Slider(
                    min: 30,
                    max: 100,
                    divisions: 14,
                    value: rider.effortPercent.toDouble().clamp(30, 100),
                    onChanged: (val) {
                      _dispatchCommand(
                        CompanionCarCommand(
                          commandId: '${DateTime.now().millisecondsSinceEpoch}',
                          type: CompanionCommandType.setEffort,
                          clientId: 'console_ds',
                          issuedAtMs: DateTime.now().millisecondsSinceEpoch,
                          riderId: rider.riderId,
                          effortPercent: val.round(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _ConsoleInteractiveButton(
                tooltip: 'Zwiększ wysiłek +5%',
                enabled: rider.effortPercent < 100,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                onPressed: () {
                  final next = (rider.effortPercent + 5).clamp(30, 100);
                  _dispatchCommand(
                    CompanionCarCommand(
                      commandId: '${DateTime.now().millisecondsSinceEpoch}',
                      type: CompanionCommandType.setEffort,
                      clientId: 'console_ds',
                      issuedAtMs: DateTime.now().millisecondsSinceEpoch,
                      riderId: rider.riderId,
                      effortPercent: next,
                    ),
                  );
                },
                child: const Text(
                  '+5%',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickOrders.map((order) {
              final active = rider.tacticalOrder == order;
              return _ConsoleInteractiveButton(
                isActive: active,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                onPressed: () {
                  _dispatchCommand(
                    CompanionCarCommand(
                      commandId: '${DateTime.now().millisecondsSinceEpoch}',
                      type: CompanionCommandType.tacticalOrder,
                      clientId: 'console_ds',
                      issuedAtMs: DateTime.now().millisecondsSinceEpoch,
                      riderId: rider.riderId,
                      orderName: order,
                    ),
                  );
                },
                child: Text(
                  order,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? AppColors.goldAccent : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONITOR 2: Taktyka Wyścigu, Luki Czasowe & Wiatr
  // ---------------------------------------------------------------------------
  Widget _buildMonitor2Tactics() {
    const teamPresets = <String>[
      'Oszczędzaj Siły',
      'Ochrona Lidera',
      'Pociąg na Czele',
      'Wachlarz (Echelon)',
      'Pełny Atak',
    ];
    final isHighCrosswind = _frame.windSpeedKmh >= 20.0;

    return _MonitorFrame(
      monitor: CompanionMonitorId.tactics,
      subtitle: 'Grupy: ${_frame.groupGaps.length} • Radar',
      accentColor: AppColors.goldAccent,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2A2F3D)),
              ),
              child: CustomPaint(
                painter: CompanionPelotonRadarPainter(
                  groups: _frame.groupGaps,
                  teamCarGapSeconds: _frame.serviceStatus.teamCarGapSeconds,
                  barrageActive: _frame.serviceStatus.barrageActive,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ..._frame.groupGaps.map((g) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _GroupGapRow(group: g),
                )),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighCrosswind
                      ? AppColors.amberWarning.withValues(alpha: 0.6)
                      : const Color(0xFF2A2F3D),
                ),
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 54,
                    height: 54,
                    child: CustomPaint(
                      painter: CompanionWindCompassPainter(
                        windDirectionDeg: _frame.windDirectionDeg,
                        windSpeedKmh: _frame.windSpeedKmh,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Wiatr: ${_frame.windSpeedKmh.toStringAsFixed(1)} km/h (${_frame.windDirectionDeg.round()}°)',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isHighCrosswind
                              ? 'Ryzyko wachlarzy (Echelons): WYSOKIE'
                              : 'Ryzyko wachlarzy: NISKIE • ${_frame.weatherLabel}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isHighCrosswind ? AppColors.amberWarning : AppColors.statusSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'PRESETY TAKTYCZNE DRUŻYNY',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: teamPresets.map((preset) {
                return _ConsoleInteractiveButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  onPressed: () {
                    _dispatchCommand(
                      CompanionCarCommand(
                        commandId: '${DateTime.now().millisecondsSinceEpoch}',
                        type: CompanionCommandType.teamPreset,
                        clientId: 'console_ds',
                        issuedAtMs: DateTime.now().millisecondsSinceEpoch,
                        presetName: preset,
                      ),
                    );
                  },
                  child: Text(
                    preset,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONITOR 3: Radio Wyścigowe & Logistyka Wozu Technicznego
  // ---------------------------------------------------------------------------
  Widget _buildMonitor3RadioAndService() {
    final service = _frame.serviceStatus;
    final barrage = service.barrageActive;

    return _MonitorFrame(
      monitor: CompanionMonitorId.radioAndService,
      subtitle: 'Dystans wozu: ${service.teamCarGapSeconds.toStringAsFixed(1)}s',
      accentColor: barrage ? AppColors.crimsonAlert : AppColors.statusSuccess,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (barrage ? AppColors.crimsonAlert : AppColors.statusSuccess)
                  .withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (barrage ? AppColors.crimsonAlert : AppColors.statusSuccess)
                    .withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  barrage ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
                  size: 16,
                  color: barrage ? AppColors.crimsonAlert : AppColors.statusSuccess,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    barrage
                        ? 'BARRAGE UCI AKTYWNY — Zakaz podjazdu do grupy'
                        : 'KONWÓJ OTWARTY — Zezwolenie na serwis z wozu',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: barrage ? AppColors.crimsonAlert : AppColors.statusSuccess,
                    ),
                  ),
                ),
                _ConsoleInteractiveButton(
                  tooltip: 'Przełącz status Barrage (Symulacja)',
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  onPressed: () {
                    _dispatchCommand(
                      CompanionCarCommand(
                        commandId: '${DateTime.now().millisecondsSinceEpoch}',
                        type: CompanionCommandType.serviceRequest,
                        clientId: 'console_ds',
                        issuedAtMs: DateTime.now().millisecondsSinceEpoch,
                        serviceType: 'barrage_toggle',
                      ),
                    );
                  },
                  child: const Text(
                    'Barrage',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _ServiceDispatchCard(
                  icon: Icons.water_drop_outlined,
                  label: 'Bidony',
                  count: service.bottlesRemaining,
                  enabled: !barrage && service.bottlesRemaining > 0,
                  onDispatch: () => _sendService('bottles'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ServiceDispatchCard(
                  icon: Icons.bolt_rounded,
                  label: 'Żele CHO',
                  count: service.gelsRemaining,
                  enabled: !barrage && service.gelsRemaining > 0,
                  onDispatch: () => _sendService('gels'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ServiceDispatchCard(
                  icon: Icons.ac_unit_rounded,
                  label: 'Ice Socks',
                  count: service.iceSocksRemaining,
                  enabled: !barrage && service.iceSocksRemaining > 0,
                  onDispatch: () => _sendService('ice'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _ServiceDispatchCard(
                  icon: Icons.pedal_bike_rounded,
                  label: 'Rowery',
                  count: service.spareBikesRemaining,
                  enabled: service.spareBikesRemaining > 0,
                  onDispatch: () => _sendService('bike'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const Text(
                'RADIO TOUR & KOMUNIKATY DS',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              _ConsoleInteractiveButton(
                tooltip: 'Wyślij testowy Ping radiowy',
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onPressed: () {
                  _dispatchCommand(
                    CompanionCarCommand(
                      commandId: '${DateTime.now().millisecondsSinceEpoch}',
                      type: CompanionCommandType.ping,
                      clientId: 'console_ds',
                      issuedAtMs: DateTime.now().millisecondsSinceEpoch,
                    ),
                  );
                },
                child: const Text(
                  'Ping Radio',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _frame.radioFeed.isEmpty
                ? const Center(
                    child: Text(
                      'Brak komunikatów radiowych.',
                      style: TextStyle(fontFamily: 'Inter', color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: _frame.radioFeed.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final event = _frame.radioFeed[index];
                      return _RadioFeedTile(event: event);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _sendService(String serviceType) {
    _dispatchCommand(
      CompanionCarCommand(
        commandId: '${DateTime.now().millisecondsSinceEpoch}',
        type: CompanionCommandType.serviceRequest,
        clientId: 'console_ds',
        issuedAtMs: DateTime.now().millisecondsSinceEpoch,
        serviceType: serviceType,
      ),
    );
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

// =============================================================================
// Reusable Monitor Frame & Interactive Components (Hover / Focus / Active / Disabled)
// =============================================================================

class _MonitorFrame extends StatelessWidget {
  const _MonitorFrame({
    required this.monitor,
    required this.subtitle,
    required this.accentColor,
    required this.child,
  });

  final CompanionMonitorId monitor;
  final String subtitle;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: Color(0xFF2A2F3D))),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  monitor.code,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    monitor.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsoleInteractiveButton extends StatefulWidget {
  const _ConsoleInteractiveButton({
    required this.child,
    required this.onPressed,
    this.enabled = true,
    this.isActive = false,
    this.tooltip,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  final Widget child;
  final VoidCallback onPressed;
  final bool enabled;
  final bool isActive;
  final String? tooltip;
  final EdgeInsetsGeometry padding;

  @override
  State<_ConsoleInteractiveButton> createState() => _ConsoleInteractiveButtonState();
}

class _ConsoleInteractiveButtonState extends State<_ConsoleInteractiveButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.background.withValues(alpha: 0.6)
        : (widget.isActive
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : (_pressed
                ? AppColors.surfaceLight
                : (_hovered ? AppColors.surfaceLight.withValues(alpha: 0.9) : AppColors.background)));

    final borderColor = !widget.enabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : (_focused
            ? AppColors.goldAccent
            : (widget.isActive
                ? AppColors.goldAccent.withValues(alpha: 0.8)
                : (_hovered ? AppColors.accentBlue.withValues(alpha: 0.6) : const Color(0xFF2A2F3D))));

    final button = FocusableActionDetector(
      enabled: widget.enabled,
      mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.45,
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      return Tooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

class _TelemetryHeaderChip extends StatelessWidget {
  const _TelemetryHeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderTelemetryTile extends StatefulWidget {
  const _RiderTelemetryTile({
    required this.rider,
    required this.isSelected,
    required this.onTap,
  });

  final CompanionRiderTelemetry rider;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_RiderTelemetryTile> createState() => _RiderTelemetryTileState();
}

class _RiderTelemetryTileState extends State<_RiderTelemetryTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rider;
    final zoneColor = AppColors.getPowerZoneColor(r.powerZone);
    final tempColor = r.coreTempC >= 39.2
        ? AppColors.crimsonAlert
        : (r.coreTempC >= 38.6 ? AppColors.amberWarning : AppColors.statusSuccess);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColors.surfaceLight
                : (_hovered ? AppColors.surfaceLight.withValues(alpha: 0.7) : AppColors.background),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.goldAccent
                  : (r.isLeader
                      ? AppColors.goldAccent.withValues(alpha: 0.4)
                      : const Color(0xFF2A2F3D)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: r.isLeader
                          ? AppColors.goldAccent.withValues(alpha: 0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${r.bibNumber}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: r.isLeader ? AppColors.goldAccent : AppColors.textSecondary,
                        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.riderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${r.watts} W',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: zoneColor,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${r.wPerKg.toStringAsFixed(2)} W/kg',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${r.heartRateBpm} bpm • ${r.cadenceRpm} rpm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      r.tacticalOrder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentBlue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _MiniProgressBar(
                      label: "W'",
                      value: r.wPrimePercent / 100.0,
                      color: r.wPrimePercent < 30 ? AppColors.crimsonAlert : AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniProgressBar(
                      label: 'Glik',
                      value: r.glycogenPercent / 100.0,
                      color: r.glycogenPercent < 30 ? AppColors.amberWarning : AppColors.statusSuccess,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${r.coreTempC.toStringAsFixed(1)}°C',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: tempColor,
                      fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
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

class _MiniProgressBar extends StatelessWidget {
  const _MiniProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 9,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: value.clamp(0.0, 1.0),
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _GroupGapRow extends StatelessWidget {
  const _GroupGapRow({required this.group});

  final CompanionGroupGap group;

  @override
  Widget build(BuildContext context) {
    final isPeloton = group.gapSeconds.abs() < 1.0;
    final sign = group.gapSeconds < 0 ? '-' : (group.gapSeconds > 0 ? '+' : '');
    final absSec = group.gapSeconds.abs().round();
    final mins = absSec ~/ 60;
    final secs = (absSec % 60).toString().padLeft(2, '0');
    final formattedGap = isPeloton ? '0:00' : '$sign$mins:$secs';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPeloton
              ? AppColors.goldAccent.withValues(alpha: 0.45)
              : const Color(0xFF2A2F3D),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              group.groupName,
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
          Text(
            '${group.riderCount} kol. (${group.teamRidersCount} naszych)',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            formattedGap,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isPeloton
                  ? AppColors.goldAccent
                  : (group.gapSeconds < 0 ? AppColors.accentBlue : AppColors.textSecondary),
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDispatchCard extends StatelessWidget {
  const _ServiceDispatchCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.enabled,
    required this.onDispatch,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool enabled;
  final VoidCallback onDispatch;

  @override
  Widget build(BuildContext context) {
    return _ConsoleInteractiveButton(
      enabled: enabled,
      tooltip: enabled ? 'Wyślij: $label' : 'Niedostępne (Barrage lub brak zapasu)',
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      onPressed: onDispatch,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.goldAccent : AppColors.textSecondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'x$count',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: count > 0 ? AppColors.accentBlue : AppColors.crimsonAlert,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadioFeedTile extends StatelessWidget {
  const _RadioFeedTile({required this.event});

  final CompanionRadioEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: event.isUrgent
            ? AppColors.amberWarning.withValues(alpha: 0.1)
            : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: event.isUrgent
              ? AppColors.amberWarning.withValues(alpha: 0.5)
              : const Color(0xFF2A2F3D),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'KM ${event.kmMark.toStringAsFixed(1)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: event.isUrgent ? AppColors.amberWarning : AppColors.accentBlue,
                  fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  event.sender,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            event.message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
