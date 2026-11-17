import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/network/dual_screen_telemetry_wall_server.dart';

TelemetryWallFrame _sampleFrame({int sequence = 1}) {
  return TelemetryWallFrame(
    sequence: sequence,
    timestampMs: 1700000000000 + sequence * 500,
    stageName: "Stage 17: Saint-Gaudens -> Alpe d'Huez",
    kmCompleted: 142.4,
    totalKm: 178.0,
    pelotonSpeedKmh: 38.6,
    windSpeedKmh: 18.0,
    windDirectionDeg: 225.0,
    temperatureC: 26.5,
    weatherLabel: 'Alpine Sun',
    riders: const [
      CompanionRiderTelemetry(
        riderId: 'r_leader',
        riderName: 'K. Majka',
        bibNumber: 1,
        role: 'GC Leader',
        watts: 415,
        wPerKg: 6.19,
        heartRateBpm: 174,
        cadenceRpm: 88,
        wPrimePercent: 78.5,
        glycogenPercent: 64.0,
        coreTempC: 38.4,
        effortPercent: 88,
        tacticalOrder: 'Tempo Climb',
        gapToLeaderSec: 0.0,
        powerZone: 5,
        isLeader: true,
      ),
      CompanionRiderTelemetry(
        riderId: 'r_dom1',
        riderName: 'M. Kwiatkowski',
        bibNumber: 2,
        role: 'Mountain Domestique',
        watts: 390,
        wPerKg: 5.74,
        heartRateBpm: 168,
        cadenceRpm: 84,
        wPrimePercent: 52.0,
        glycogenPercent: 58.0,
        coreTempC: 38.1,
        effortPercent: 85,
        tacticalOrder: 'Protect Leader',
        gapToLeaderSec: 1.2,
        powerZone: 4,
      ),
    ],
    groupGaps: const [
      CompanionGroupGap(
        groupName: 'Breakaway',
        gapSeconds: -84.0,
        riderCount: 6,
        teamRidersCount: 0,
      ),
      CompanionGroupGap(
        groupName: 'Maillot Jaune Group',
        gapSeconds: 0.0,
        riderCount: 28,
        teamRidersCount: 4,
      ),
    ],
    radioFeed: const [
      CompanionRadioEvent(
        id: 'rad_1',
        kmMark: 142.0,
        sender: 'DS Car 1',
        message: 'Hold 6.1 W/kg until Hairpin 7, ice socks ready at km 145.',
        isUrgent: true,
      ),
    ],
    serviceStatus: const CompanionServiceStatus(
      teamCarGapSeconds: 22.0,
      barrageActive: false,
      bottlesRemaining: 28,
      gelsRemaining: 19,
      iceSocksRemaining: 8,
      spareBikesRemaining: 6,
    ),
  );
}

void main() {
  group('DualScreenTelemetryWallServer models & serialization', () {
    test('TelemetryWallFrame round-trips through JSON losslessly', () {
      final frame = _sampleFrame(sequence: 42);
      final decoded = TelemetryWallFrame.fromJson(frame.toJson());

      expect(decoded.sequence, 42);
      expect(decoded.stageName, frame.stageName);
      expect(decoded.kmRemaining, closeTo(35.6, 0.01));
      expect(decoded.riders.length, 2);
      expect(decoded.riders.first.isLeader, isTrue);
      expect(decoded.riders.first.watts, 415);
      expect(decoded.groupGaps.length, 2);
      expect(decoded.radioFeed.first.isUrgent, isTrue);
      expect(decoded.serviceStatus.iceSocksRemaining, 8);
    });

    test('CompanionCarCommand round-trips through JSON', () {
      const cmd = CompanionCarCommand(
        commandId: 'cmd_99',
        type: CompanionCommandType.setEffort,
        clientId: 'tablet_1',
        issuedAtMs: 1700000100000,
        riderId: 'r_leader',
        effortPercent: 94,
      );
      final decoded = CompanionCarCommand.fromJson(cmd.toJson());
      expect(decoded.commandId, 'cmd_99');
      expect(decoded.type, CompanionCommandType.setEffort);
      expect(decoded.riderId, 'r_leader');
      expect(decoded.effortPercent, 94);
    });
  });

  group('DualScreenTelemetryWallServer live WebSocket & HTTP', () {
    late DualScreenTelemetryWallServer server;
    late DualScreenTelemetryWallClient client;

    setUp(() {
      server = DualScreenTelemetryWallServer(maxClients: 2);
      client = DualScreenTelemetryWallClient();
    });

    tearDown(() async {
      await client.dispose();
      await server.dispose();
    });

    test('starts, serves /health and /, authenticates client, and exchanges frames & commands', () async {
      await server.start(bindAddress: '127.0.0.1', port: 0, customPin: '482910');
      expect(server.status, DualScreenServerStatus.running);
      expect(server.boundPort, greaterThan(0));
      expect(server.pairingPin, '482910');

      // Verify HTTP /health and / endpoints via raw TCP socket (bypasses TestWidgets HttpOverrides).
      Future<String> httpGet(String path) async {
        final socket = await Socket.connect('127.0.0.1', server.boundPort);
        socket.write('GET $path HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n');
        await socket.flush();
        final response = await utf8.decodeStream(socket);
        await socket.close();
        return response;
      }

      final healthResp = await httpGet('/health');
      expect(healthResp, contains('200 OK'));
      expect(healthResp, contains('"status":"running"'));

      final htmlResp = await httpGet('/');
      expect(htmlResp, contains('200 OK'));
      expect(htmlResp, contains('TEAM CAR TELEMETRY WALL'));

      // Connect companion WebSocket client with valid PIN.
      final receivedFrames = <TelemetryWallFrame>[];
      final receivedCommands = <CompanionCarCommand>[];
      final receivedAcks = <Map<String, dynamic>>[];

      final frameSub = client.frameStream.listen(receivedFrames.add);
      final cmdSub = server.commandStream.listen(receivedCommands.add);
      final ackSub = client.ackStream.listen(receivedAcks.add);

      await client.connect(
        host: '127.0.0.1',
        port: server.boundPort,
        pin: '482910',
        deviceName: 'iPad Pro Team Car',
        platform: 'iPadOS',
      );

      // Allow handshake welcome to settle.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(client.isConnected, isTrue);
      expect(client.isAuthenticated, isTrue);
      expect(server.connectedDevices.length, 1);
      expect(server.connectedDevices.first.deviceName, 'iPad Pro Team Car');

      // Broadcast telemetry frame from host to companion.
      final delivered = server.broadcastTelemetryFrame(_sampleFrame(sequence: 7));
      expect(delivered, 1);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(receivedFrames.length, 1);
      expect(receivedFrames.first.sequence, 7);
      expect(receivedFrames.first.riders.length, 2);

      // Send tactical effort command from companion to host.
      client.sendCommand(
        const CompanionCarCommand(
          commandId: 'cmd_effort_1',
          type: CompanionCommandType.setEffort,
          clientId: 'ignored_by_server',
          issuedAtMs: 1700000200000,
          riderId: 'r_leader',
          effortPercent: 95,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(receivedCommands.length, 1);
      expect(receivedCommands.first.type, CompanionCommandType.setEffort);
      expect(receivedCommands.first.effortPercent, 95);
      expect(receivedAcks.any((a) => a['commandId'] == 'cmd_effort_1'), isTrue);
      expect(server.commandsProcessedCount, 1);

      await frameSub.cancel();
      await cmdSub.cancel();
      await ackSub.cancel();
    });

    test('rejects wrong PIN and blocks unauthenticated commands', () async {
      await server.start(bindAddress: '127.0.0.1', port: 0, customPin: '123456');

      final receivedCommands = <CompanionCarCommand>[];
      final cmdSub = server.commandStream.listen(receivedCommands.add);

      await client.connect(
        host: '127.0.0.1',
        port: server.boundPort,
        pin: '000000',
        deviceName: 'Unauthorized Phone',
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(client.isAuthenticated, isFalse);

      client.sendCommand(
        const CompanionCarCommand(
          commandId: 'cmd_bad',
          type: CompanionCommandType.teamPreset,
          clientId: 'x',
          issuedAtMs: 1700000200000,
          presetName: 'FullGas',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(receivedCommands, isEmpty);

      await cmdSub.cancel();
    });
  });

  group('DualScreenTelemetryWallNotifier', () {
    test('manages server start, pin regeneration, and stop cleanly', () async {
      final notifier = DualScreenTelemetryWallNotifier();
      expect(notifier.state.status, DualScreenServerStatus.stopped);

      await notifier.startServer(port: 0, bindAddress: '127.0.0.1');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(notifier.state.isRunning, isTrue);
      expect(notifier.state.port, greaterThan(0));
      expect(notifier.state.pairingPin.length, 6);

      final oldPin = notifier.state.pairingPin;
      notifier.regeneratePin();
      expect(notifier.state.pairingPin.length, 6);
      expect(notifier.state.wsUrl, contains(notifier.state.pairingPin));
      // PIN may occasionally collide in 1/900000, so just verify format is 6 digits.
      expect(RegExp(r'^\d{6}$').hasMatch(oldPin), isTrue);

      await notifier.stopServer();
      expect(notifier.state.status, DualScreenServerStatus.stopped);
      notifier.dispose();
    });
  });

  group('DualScreenTelemetryWallPanel responsive widget tests', () {
    final connectedState = DualScreenTelemetryWallState(
      status: DualScreenServerStatus.running,
      port: 8765,
      pairingPin: '551920',
      wsUrl: 'ws://192.168.1.42:8765/ws?pin=551920',
      dashboardUrl: 'http://192.168.1.42:8765/?pin=551920',
      framesBroadcast: 124,
      commandsProcessed: 9,
      connectedDevices: [
        ConnectedCompanionDevice(
          clientId: 'c1',
          deviceName: 'Galaxy Tab S9 Team Car',
          platform: 'Android Tablet',
          remoteAddress: '192.168.1.88',
          connectedAt: DateTime(2026, 7, 14, 14, 10),
          lastSeenAt: DateTime(2026, 7, 14, 14, 15),
          authenticated: true,
          rttMs: 11,
          commandsSent: 9,
        ),
      ],
      recentLogs: const [
        '[14:10:02] Telemetry Wall server listening on 127.0.0.1:8765 (PIN: 551920)',
        '[14:10:15] Authenticated Galaxy Tab S9 Team Car',
      ],
    );

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          var toggled = 0;
          var pinRefreshed = 0;
          String? kickedId;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: DualScreenTelemetryWallPanel(
                  state: connectedState,
                  onToggleServer: () => toggled++,
                  onRegeneratePin: () => pinRefreshed++,
                  onDisconnectDevice: (id) => kickedId = id,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('TEAM CAR TELEMETRY WALL'), findsOneWidget);
          expect(find.text('551920'), findsOneWidget);
          expect(find.text('Galaxy Tab S9 Team Car'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await tester.tap(find.text('Stop Server'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('New PIN'));
          await tester.pump(const Duration(milliseconds: 100));
          await tester.tap(find.text('Kick'));
          await tester.pump(const Duration(milliseconds: 100));

          expect(toggled, 1);
          expect(pinRefreshed, 1);
          expect(kickedId, 'c1');
        },
      );
    }

    testWidgets('renders disabled and error states cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DualScreenTelemetryWallPanel(
              state: const DualScreenTelemetryWallState(
                status: DualScreenServerStatus.error,
                errorMessage: 'Port 8765 already in use',
              ),
              enabled: false,
              onToggleServer: () {},
              onRegeneratePin: () {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ERROR'), findsOneWidget);
      expect(find.text('Port 8765 already in use'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
