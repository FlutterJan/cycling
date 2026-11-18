import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/equipment_wind_tunnel_custom_decals_and_serials.dart';

void main() {
  group('EquipmentWindTunnelCustomDecalsService', () {
    const service = EquipmentWindTunnelCustomDecalsService();

    test('createInitialState populates serialized frames and gold editions', () {
      final state = service.createInitialState(initialBudgetEur: 500000);

      expect(state.frames.length, 4);
      expect(state.goldEditionsCount, 3);
      expect(state.museumFramesCount, 1);
      expect(state.selectedFrame, isNotNull);
      expect(state.availableBudgetEur, 500000);
      expect(state.nextSequenceCounter, 5);
    });

    test('generateSerialNumber formats deterministic serial codes', () {
      final serial = service.generateSerialNumber(
        edition: ChampionshipEditionType.worldChampionRainbow,
        seasonYear: 2026,
        sequence: 12,
      );

      expect(serial, 'PPM-26-WC-0012');
    });

    test('mintCustomSerialFrame creates new serialized frame and deducts budget', () {
      final initial = service.createInitialState(initialBudgetEur: 100000);
      final updated = service.mintCustomSerialFrame(
        state: initial,
        frameModelId: 'tarmac_sl8',
        frameModelName: 'S-Works Tarmac SL8',
        manufacturerName: 'Specialized Lab',
        editionType: ChampionshipEditionType.olympicGold,
        finishStyle: DecalFinishStyle.glossMetallicGold,
        customTopTubeInscription: 'PARIS 2026 GOLD',
        nationalFlagCode: 'pol',
        assignedRiderId: 'r_10',
        assignedRiderName: 'Kacper Majewski',
      );

      expect(updated.lastError, isNull);
      expect(updated.frames.length, 5);
      expect(updated.selectedSerialNumber, 'PPM-26-OG-0005');
      expect(updated.selectedFrame!.nationalFlagCode, 'POL');
      expect(updated.selectedFrame!.status, SerialFrameStatus.assignedToRider);
      expect(updated.selectedFrame!.isGoldMasterEdition, isTrue);
      expect(
        updated.availableBudgetEur,
        100000 -
            (ChampionshipEditionType.olympicGold.upgradeCostEur +
                DecalFinishStyle.glossMetallicGold.paintShopFeeEur),
      );
    });

    test('mintCustomSerialFrame rejects empty model name or insufficient budget', () {
      final initial = service.createInitialState(initialBudgetEur: 1000);

      final emptyModel = service.mintCustomSerialFrame(
        state: initial,
        frameModelId: 'x',
        frameModelName: '   ',
        manufacturerName: 'Atelier',
        editionType: ChampionshipEditionType.standardTeamIssue,
        finishStyle: DecalFinishStyle.matteStealthCarbon,
        customTopTubeInscription: 'TEST',
        nationalFlagCode: 'POL',
      );
      expect(emptyModel.lastError, isNotNull);

      final lowBudget = service.mintCustomSerialFrame(
        state: initial,
        frameModelId: 'x',
        frameModelName: 'Aeroad CFR',
        manufacturerName: 'Canyon',
        editionType: ChampionshipEditionType.olympicGold,
        finishStyle: DecalFinishStyle.glossMetallicGold,
        customTopTubeInscription: 'TEST',
        nationalFlagCode: 'POL',
      );
      expect(lowBudget.lastError, isNotNull);
      expect(lowBudget.frames.length, initial.frames.length);
    });

    test('upgradeToChampionshipEdition upgrades raw carbon to gold edition', () {
      final initial = service.createInitialState(initialBudgetEur: 100000);
      const rawSerial = 'PPM-26-SW-0004';

      final upgraded = service.upgradeToChampionshipEdition(
        state: initial,
        serialNumber: rawSerial,
        targetEdition: ChampionshipEditionType.grandTourYellowGold,
        targetFinish: DecalFinishStyle.brushedTitaniumLeaf,
        customInscription: 'MAILLOT JAUNE 2026',
      );

      expect(upgraded.lastError, isNull);
      expect(upgraded.selectedSerialNumber, 'PPM-26-GT-0005');
      expect(
        upgraded.selectedFrame!.editionType,
        ChampionshipEditionType.grandTourYellowGold,
      );
      expect(
        upgraded.selectedFrame!.customTopTubeInscription,
        'MAILLOT JAUNE 2026',
      );
    });

    test('assignFrameToRider, recordRaceUsage, and archiveToClubMuseum workflow', () {
      var state = service.createInitialState(initialBudgetEur: 150000);
      const rawSerial = 'PPM-26-SW-0004';

      state = service.assignFrameToRider(
        state: state,
        serialNumber: rawSerial,
        riderId: 'r_99',
        riderName: 'Janek Góral',
      );
      var frame = state.frames.firstWhere((f) => f.serialNumber == rawSerial);
      expect(frame.status, SerialFrameStatus.assignedToRider);
      expect(frame.assignedRiderName, 'Janek Góral');

      final prevValue = frame.estimatedCollectorValueEur;
      state = service.recordRaceUsage(
        state: state,
        serialNumber: rawSerial,
        addedKilometers: 420,
        addedVictories: 2,
        addedMonuments: 1,
      );
      frame = state.frames.firstWhere((f) => f.serialNumber == rawSerial);
      expect(frame.victoriesCount, 3);
      expect(frame.monumentsWon, 1);
      expect(frame.estimatedCollectorValueEur, greaterThan(prevValue));

      final valueBeforeMuseum = frame.estimatedCollectorValueEur;
      state = service.archiveToClubMuseum(
        state: state,
        serialNumber: rawSerial,
      );
      frame = state.frames.firstWhere((f) => f.serialNumber == rawSerial);
      expect(frame.status, SerialFrameStatus.museumArchived);
      expect(frame.assignedRiderName, isNull);
      expect(frame.estimatedCollectorValueEur, greaterThan(valueBeforeMuseum));
    });

    test('JSON round-trip serialization preserves state', () {
      final initial = service.createInitialState(initialBudgetEur: 250000);
      final json = initial.toJson();
      final restored = EquipmentWindTunnelDecalsState.fromJson(json);

      expect(restored.frames.length, initial.frames.length);
      expect(restored.selectedSerialNumber, initial.selectedSerialNumber);
      expect(restored.availableBudgetEur, initial.availableBudgetEur);
      expect(
        restored.frames.first.customTopTubeInscription,
        initial.frames.first.customTopTubeInscription,
      );
    });
  });

  group('EquipmentWindTunnelCustomDecalsPanel widget tests', () {
    Future<void> pumpPanelAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: EquipmentWindTunnelCustomDecalsPanel(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 mobile without overflow', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(390, 844));
      expect(
        find.text('Numery Seryjne Ram & Złote Edycje Mistrzowskie'),
        findsOneWidget,
      );
      expect(find.text('PPM-26-WC-0001'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 tablet without overflow', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1024, 768));
      expect(find.text('Cervélo S5 Rainbow Gold'), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 desktop and supports minting', (
      tester,
    ) async {
      await pumpPanelAtSize(tester, const Size(1600, 900));

      await tester.tap(find.text('Nowa Rama / Serial'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Rejestracja Nowego Numeru Seryjnego & Kalkomanii'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Nadaj Serial & Lakieruj'));
      await tester.tap(find.text('Nadaj Serial & Lakieruj'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('PPM-26-WC-0005'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
