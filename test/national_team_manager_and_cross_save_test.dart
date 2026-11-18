// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/national_federation_team_manager_mode.dart';
import 'package:pro_peloton_manager/services/career/transfer_deadline_day_live_event.dart';
import 'package:pro_peloton_manager/services/database/cloud_cross_save_json_sync_adapter.dart';

void main() {
  group('National Federation Team Manager (#563 / #605)', () {
    const service = NationalFederationTeamManagerService();

    test('autoSelectOptimalSquad selects eligible starters within UCI quota',
        () {
      final base =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final selected = service.autoSelectOptimalSquad(base);

      expect(
        selected.activeStarters.length,
        lessThanOrEqualTo(selected.activeMaxStarters),
      );
      expect(selected.activeStarters, isNotEmpty);
      expect(
        selected.activeStarters
            .any((e) => e.role == NationalRiderTacticalRole.protectedLeader),
        isTrue,
      );

      // Locked selection prevents changes
      final locked = service.setSelectionLocked(selected, true);
      final afterLockedAuto = service.autoSelectOptimalSquad(locked);
      expect(
        afterLockedAuto.statusBannerPl,
        contains('zablokowane'),
      );
    });

    test('evaluateSquadChemistry detects ego, club and rivalry conflicts', () {
      final base =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final customPool = [
        const NationalSelectionRiderCandidate(
          riderId: 'r_star_1',
          fullName: 'Gwiazda Ego',
          tradeTeamName: 'Team A',
          nationalityCode: 'POL',
          age: 27,
          flatRating: 82,
          mountainRating: 84,
          puncheurRating: 86,
          timeTrialRating: 80,
          sprintRating: 78,
          staminaRating: 85,
          tacticalIq: 82,
          seasonUciPoints: 1500,
          currentFormScore: 88,
          fatigueScore: 20,
          morale: 85,
          egoLevel: 85,
          hasClubConflict: true,
          rivalRiderIds: ['r_star_2'],
        ),
        const NationalSelectionRiderCandidate(
          riderId: 'r_star_2',
          fullName: 'Rywal Szosowy',
          tradeTeamName: 'Team B',
          nationalityCode: 'POL',
          age: 28,
          flatRating: 81,
          mountainRating: 80,
          puncheurRating: 82,
          timeTrialRating: 77,
          sprintRating: 75,
          staminaRating: 82,
          tacticalIq: 84,
          seasonUciPoints: 1200,
          currentFormScore: 84,
          fatigueScore: 22,
          morale: 82,
          egoLevel: 65,
          rivalRiderIds: ['r_star_1'],
        ),
      ];

      final campaign = base.copyWith(
        candidatePool: customPool,
        selectedSquad: const [
          NationalSquadSelectionEntry(
            riderId: 'r_star_1',
            role: NationalRiderTacticalRole.superDomestique,
          ),
          NationalSquadSelectionEntry(
            riderId: 'r_star_2',
            role: NationalRiderTacticalRole.protectedLeader,
          ),
        ],
      );

      final report = service.evaluateSquadChemistry(campaign);
      expect(report.egoConflictCount, 1);
      expect(report.tradeTeamConflictCount, 1);
      expect(report.rivalryCount, 1);
      expect(report.isEligibleToStart, isTrue);
      expect(report.warnings.length, greaterThanOrEqualTo(3));

      // Empty squad is not eligible
      final emptyReport = service.evaluateSquadChemistry(
        campaign.copyWith(selectedSquad: const []),
      );
      expect(emptyReport.isEligibleToStart, isFalse);
      expect(emptyReport.cohesionScore, 0.0);
    });

    test('resolveClubReleaseNegotiation clears club conflict and deducts budget',
        () {
      final base =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final conflicted = base.candidatePool.firstWhere((c) => c.hasClubConflict);
      final initialBudget = base.quota.federationBudgetEur;

      final resolved = service.resolveClubReleaseNegotiation(
        base,
        conflicted.riderId,
      );
      final updatedCandidate = resolved.findCandidate(conflicted.riderId)!;

      expect(updatedCandidate.hasClubConflict, isFalse);
      expect(
        resolved.quota.federationBudgetEur,
        initialBudget -
            NationalFederationTeamManagerService.clubReleaseNegotiationCostEur,
      );
    });

    test('switchEventAndCourse trims starters when moving from Road to ITT', () {
      final base =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final roadSquad = service.autoSelectOptimalSquad(base);
      expect(roadSquad.activeStarters.length, greaterThan(2));

      final ittSquad = service.switchEventAndCourse(
        roadSquad,
        eventType: NationalChampionshipEventType.uciIttWorldChampionships,
      );
      expect(
        ittSquad.courseProfile,
        NationalTeamCourseProfile.technicalTimeTrial,
      );
      expect(
        ittSquad.activeStarters.length,
        lessThanOrEqualTo(ittSquad.activeMaxStarters),
      );
    });

    test('simulateChampionshipRace is deterministic and serializes cleanly',
        () {
      final base =
          NationalFederationTeamManagerService.createDefaultPolandCampaign();
      final prepared = service.autoSelectOptimalSquad(base);

      final simA = service.simulateChampionshipRace(
        prepared,
        deterministicSeed: 4242,
      );
      final simB = service.simulateChampionshipRace(
        prepared,
        deterministicSeed: 4242,
      );

      expect(simA.lastSimulationResult, isNotNull);
      expect(simA.isSelectionLocked, isTrue);
      expect(
        simA.lastSimulationResult!.bestFinishPosition,
        simB.lastSimulationResult!.bestFinishPosition,
      );
      expect(
        simA.lastSimulationResult!.uciNationPointsEarned,
        simB.lastSimulationResult!.uciNationPointsEarned,
      );

      final json = simA.toJson();
      final restored = NationalChampionshipCampaignState.fromJson(json);
      expect(restored.quota.nationCode, simA.quota.nationCode);
      expect(restored.history.length, simA.history.length);
      expect(
        restored.lastSimulationResult?.bestFinishPosition,
        simA.lastSimulationResult?.bestFinishPosition,
      );
    });

    test('NationalFederationTeamManagerNotifier updates state via actions', () {
      final notifier = NationalFederationTeamManagerNotifier();
      notifier.autoSelectOptimalSquad();
      expect(notifier.state.activeStarters, isNotEmpty);

      notifier.simulateChampionship(deterministicSeed: 777);
      expect(notifier.state.lastSimulationResult, isNotNull);
      expect(notifier.state.isSelectionLocked, isTrue);
      notifier.dispose();
    });
  });

  group('Transfer Deadline Day Live Event (#588 / #605)', () {
    const service = TransferDeadlineDayLiveEventService();

    test('createInitialState populates offers, ticker and budgets', () {
      final state = service.createInitialState(seed: 2026);

      expect(state.offers, isNotEmpty);
      expect(state.tickerFeed, isNotEmpty);
      expect(state.isWindowClosed, isFalse);
      expect(state.remainingWindowMinutes, state.config.totalDurationMinutes);
      expect(state.remainingRosterSlots, state.config.openRosterSlots);
    });

    test('advanceTime counts down, expires offers and closes window at 00:00',
        () {
      final initial = service.createInitialState(
        config: const TransferDeadlineDayConfig(totalDurationMinutes: 60),
        seed: 99,
      );

      final mid = service.advanceTime(initial, minutes: 30, seed: 99);
      expect(mid.remainingWindowMinutes, 30);
      expect(mid.currentPhase, DeadlinePhase.goldenHour);

      final closed = service.advanceTime(mid, minutes: 30, seed: 99);
      expect(closed.remainingWindowMinutes, 0);
      expect(closed.isWindowClosed, isTrue);
      expect(closed.currentPhase, DeadlinePhase.windowClosed);
      expect(closed.activeOffersCount, 0);
    });

    test('acceptOffer updates budgets, roster slots, deals and ticker', () {
      final initial = service.createInitialState(seed: 2026);
      final target = initial.offers.firstWhere(
        (o) =>
            o.isActionable &&
            o.askingSalaryEur <= initial.remainingWageBudgetEur &&
            (o.signingBonusEur + o.releaseBuyoutEur) <=
                initial.remainingTransferBudgetEur,
      );

      final acceptedState = service.acceptOffer(initial, target.id);
      expect(
        acceptedState.remainingWageBudgetEur,
        initial.remainingWageBudgetEur - target.askingSalaryEur,
      );
      expect(
        acceptedState.remainingTransferBudgetEur,
        initial.remainingTransferBudgetEur -
            (target.signingBonusEur + target.releaseBuyoutEur),
      );
      expect(
        acceptedState.remainingRosterSlots,
        initial.remainingRosterSlots - 1,
      );
      expect(acceptedState.completedDeals.length, 1);
      expect(acceptedState.completedDeals.first.riderName, target.riderName);
      expect(acceptedState.tickerFeed.first.isBreaking, isTrue);

      // Cannot accept again after window closes
      final closedState = acceptedState.copyWith(remainingWindowMinutes: 0);
      final afterClosed = service.acceptOffer(closedState, target.id);
      expect(afterClosed.lastActionFeedback, contains('zamknięte'));
    });

    test('submitCounterOffer handles insulting rejection and high acceptance',
        () {
      final initial = service.createInitialState(seed: 123);
      final offer = initial.offers.first;

      // Insulting counter-offer (< 65% of asking salary)
      final lowSalary = (offer.askingSalaryEur * 0.50).round();
      final rejectedState = service.submitCounterOffer(
        initial,
        offerId: offer.id,
        counterSalaryEur: lowSalary,
        counterYears: 2,
        counterRole: RiderRole.domestique,
        seed: 1,
      );
      final updatedRejected =
          rejectedState.offers.firstWhere((o) => o.id == offer.id);
      expect(updatedRejected.status, DeadlineOfferStatus.rejected);

      // Generous counter-offer (>= 95% of asking salary)
      final highSalary = offer.askingSalaryEur;
      final acceptedState = service.submitCounterOffer(
        initial,
        offerId: offer.id,
        counterSalaryEur: highSalary,
        counterYears: 2,
        counterRole: offer.proposedRole,
        seed: 2,
      );
      final updatedAccepted =
          acceptedState.offers.firstWhere((o) => o.id == offer.id);
      expect(updatedAccepted.status, DeadlineOfferStatus.accepted);
      expect(acceptedState.completedDeals.length, 1);
    });

    test('TransferDeadlineDayState JSON round-trip and Notifier work', () {
      final notifier = TransferDeadlineDayNotifier(seed: 2026);
      notifier.setSpeedMultiplier(4);
      expect(notifier.state.simulationSpeedMultiplier, 4);

      notifier.advanceMinutes(20);
      expect(
        notifier.state.remainingWindowMinutes,
        notifier.state.config.totalDurationMinutes - 20,
      );

      final json = notifier.state.toJson();
      final restored = TransferDeadlineDayState.fromJson(json);
      expect(
        restored.remainingWindowMinutes,
        notifier.state.remainingWindowMinutes,
      );
      expect(restored.offers.length, notifier.state.offers.length);

      notifier.dispose();
    });
  });

  group('GZIP Compression & Cross-Save Sync Adapter (#591 / #605)', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ppm_cross_save_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Map<String, dynamic> buildSampleSave({
      String saveId = 'save_pol_2026',
      int seasonYear = 2026,
      String notes = 'Line 1\r\nLine 2\r\nŻółć i gęślą jaźń',
    }) {
      return {
        'id': saveId,
        'saveName': 'Kariera WorldTour Polska',
        'playerManagerName': 'Jan Kowalski',
        'currentSeasonYear': seasonYear,
        'currentDate': '2026-07-14T12:00:00.000Z',
        'playerTeam': {
          'name': 'Biało-Czerwoni Pro Cycling',
          'budgetEur': 4500000,
        },
        'notes': notes,
        'roster': List.generate(
          25,
          (i) => {
            'id': 'rider_$i',
            'name': 'Kolarz Numer $i',
            'ftp': 380 + i,
            'weightKg': 68.5,
            'morale': 85,
          },
        ),
      };
    }

    final pcDevice = CrossSaveDeviceProfile(
      deviceId: 'win_pc_01',
      deviceName: 'Desktop Windows',
      platform: CrossSaveDevicePlatform.pcWindows,
      appVersion: '0.1.0+1',
      lastSeenAt: DateTime.utc(2026, 7, 14, 12, 0),
    );

    final macDevice = CrossSaveDeviceProfile(
      deviceId: 'mac_studio_02',
      deviceName: 'MacBook Pro M3',
      platform: CrossSaveDevicePlatform.macOs,
      appVersion: '0.1.0+1',
      lastSeenAt: DateTime.utc(2026, 7, 14, 12, 5),
    );

    test('GZIP compression level 1..9 shrinks payload and restores losslessly',
        () {
      final adapter = CloudCrossSaveJsonSyncAdapter();
      final rawSave = buildSampleSave();

      final packetL1 = adapter.compressRawJson(
        jsonMap: rawSave,
        sourceDevice: pcDevice,
        compressionLevel: 1,
      );
      final packetL9 = adapter.compressRawJson(
        jsonMap: rawSave,
        sourceDevice: pcDevice,
        compressionLevel: 9,
      );

      expect(packetL9.magicHeader, kCrossSavePacketMagic);
      expect(
        packetL9.metadata.compressedBytes,
        lessThan(packetL9.metadata.uncompressedBytes),
      );
      expect(
        packetL9.metadata.compressedBytes,
        lessThanOrEqualTo(packetL1.metadata.compressedBytes),
      );

      final decoded = adapter.decompressToJson(packetL9);
      expect(decoded['id'], 'save_pol_2026');
      expect(decoded['currentSeasonYear'], 2026);
      // CRLF normalized to LF for cross-platform consistency
      expect(decoded['notes'], 'Line 1\nLine 2\nŻółć i gęślą jaźń');
      expect((decoded['roster'] as List).length, 25);
    });

    test('decompressToJson rejects tampered magic, base64, gzip and checksums',
        () {
      final adapter = CloudCrossSaveJsonSyncAdapter();
      final packet = adapter.compressRawJson(
        jsonMap: buildSampleSave(),
        sourceDevice: pcDevice,
      );

      // Invalid magic header
      final badMagic = CrossSaveCompressedPacket(
        magicHeader: 'BAD_MAGIC',
        metadata: packet.metadata,
        gzipPayloadBase64: packet.gzipPayloadBase64,
      );
      expect(
        () => adapter.decompressToJson(badMagic),
        throwsA(
          isA<CrossSaveIntegrityException>()
              .having((e) => e.code, 'code', 'INVALID_MAGIC'),
        ),
      );

      // Invalid Base64
      final badBase64 = CrossSaveCompressedPacket(
        magicHeader: packet.magicHeader,
        metadata: packet.metadata,
        gzipPayloadBase64: '!!!not-base64!!!',
      );
      expect(
        () => adapter.decompressToJson(badBase64),
        throwsA(
          isA<CrossSaveIntegrityException>()
              .having((e) => e.code, 'code', 'INVALID_BASE64'),
        ),
      );

      // Corrupted GZIP bytes
      final badGzip = CrossSaveCompressedPacket(
        magicHeader: packet.magicHeader,
        metadata: packet.metadata,
        gzipPayloadBase64: base64Encode([1, 2, 3, 4, 5]),
      );
      expect(
        () => adapter.decompressToJson(badGzip),
        throwsA(
          isA<CrossSaveIntegrityException>()
              .having((e) => e.code, 'code', 'GZIP_DECODE_FAILED'),
        ),
      );

      // FNV-1a64 checksum mismatch
      final badFnvMeta = CrossSaveEnvelopeMetadata.fromJson({
        ...packet.metadata.toJson(),
        'fnv1a64Checksum': '0000000000000000',
      });
      final badFnvPacket = CrossSaveCompressedPacket(
        magicHeader: packet.magicHeader,
        metadata: badFnvMeta,
        gzipPayloadBase64: packet.gzipPayloadBase64,
      );
      expect(
        () => adapter.decompressToJson(badFnvPacket),
        throwsA(
          isA<CrossSaveIntegrityException>()
              .having((e) => e.code, 'code', 'FNV1A_MISMATCH'),
        ),
      );

      // CRC-32 checksum mismatch
      final badCrcMeta = CrossSaveEnvelopeMetadata.fromJson({
        ...packet.metadata.toJson(),
        'crc32Checksum': '00000000',
      });
      final badCrcPacket = CrossSaveCompressedPacket(
        magicHeader: packet.magicHeader,
        metadata: badCrcMeta,
        gzipPayloadBase64: packet.gzipPayloadBase64,
      );
      expect(
        () => adapter.decompressToJson(badCrcPacket),
        throwsA(
          isA<CrossSaveIntegrityException>()
              .having((e) => e.code, 'code', 'CRC32_MISMATCH'),
        ),
      );
    });

    test('portable token PPMCS1 and .ppmsave.gz file round-trip across devices',
        () async {
      final adapter = CloudCrossSaveJsonSyncAdapter();
      final packet = adapter.compressRawJson(
        jsonMap: buildSampleSave(),
        sourceDevice: pcDevice,
      );

      final token = adapter.encodePortableToken(packet);
      expect(token.startsWith(kCrossSaveTokenPrefix), isTrue);

      final decodedPacket = adapter.decodePortableToken(token);
      final restoredJson = adapter.decompressToJson(decodedPacket);
      expect(restoredJson['saveName'], 'Kariera WorldTour Polska');

      expect(
        () => adapter.decodePortableToken('INVALID:abc'),
        throwsA(
          isA<CrossSaveIntegrityException>()
              .having((e) => e.code, 'code', 'INVALID_TOKEN_PREFIX'),
        ),
      );

      final exportedFile = await adapter.exportToCompressedFile(
        packet: packet,
        targetDirectory: tempDir,
      );
      expect(await exportedFile.exists(), isTrue);
      expect(exportedFile.path.endsWith(kCrossSaveFileExtension), isTrue);

      final importedPacket =
          await adapter.importFromCompressedFile(exportedFile);
      final fileJson = adapter.decompressToJson(importedPacket);
      expect(fileJson['id'], 'save_pol_2026');
    });

    test('cloud transport detects cross-device conflict', () async {
      final transport = InMemoryCrossSaveCloudTransport();
      final adapter = CloudCrossSaveJsonSyncAdapter(transport: transport);

      final pcPacket = adapter.compressRawJson(
        jsonMap: buildSampleSave(seasonYear: 2026),
        sourceDevice: pcDevice,
      );
      await transport.pushSlot(slotKey: 'slot_main', packet: pcPacket);

      final macPacket = adapter.compressRawJson(
        jsonMap: buildSampleSave(seasonYear: 2027),
        sourceDevice: macDevice,
      );
      final conflict = await adapter.detectConflict(
        slotKey: 'slot_main',
        localMetadata: macPacket.metadata,
        localDevice: macDevice,
      );

      expect(conflict, isNotNull);
      expect(conflict!.remoteDevice.platform, CrossSaveDevicePlatform.pcWindows);
      expect(conflict.localDevice.platform, CrossSaveDevicePlatform.macOs);
    });
  });

  group('Responsive UI Smoke Tests (390x844 / 1024x768 / 1600x900)', () {
    const viewports = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    Future<void> pumpAtViewport(
      WidgetTester tester,
      Size size,
      Widget child,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(body: child),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (final size in viewports) {
      testWidgets(
        'NationalFederationTeamManagerPanel renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpAtViewport(
            tester,
            size,
            const NationalFederationTeamManagerPanel(),
          );
          expect(find.byType(NationalFederationTeamManagerPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'TransferDeadlineDayPanel renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpAtViewport(
            tester,
            size,
            const TransferDeadlineDayPanel(),
          );
          expect(find.byType(TransferDeadlineDayPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'CloudCrossSaveJsonSyncPanel renders cleanly at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await pumpAtViewport(
            tester,
            size,
            const CloudCrossSaveJsonSyncPanel(),
          );
          expect(find.byType(CloudCrossSaveJsonSyncPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
