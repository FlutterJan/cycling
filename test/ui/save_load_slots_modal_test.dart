import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/career/career_save.dart';
import 'package:pro_peloton_manager/services/database/save_game_manager.dart';
import 'package:pro_peloton_manager/ui/widgets/save_load_slots_modal.dart';

List<SaveSlotEnrichedInfo> _buildMockSlots() {
  final autoSave = SaveSlotEnrichedInfo(
    slot: SaveSlotInfo(
      slotNumber: 0,
      slotKey: 'autosave',
      isOccupied: true,
      isAutoSave: true,
      saveId: 'auto_1',
      saveName: 'Auto-Save Tour de France',
      playerManagerName: 'Jan Kowalski',
      playerTeamId: 'wt_aethel',
      playerTeamName: 'Aethelgard Veloce',
      playerTeamDivision: 'WT',
      playerTeamJerseyPrimaryHex: '#8E4A49',
      currentSeasonYear: 2026,
      currentDate: DateTime(2026, 7, 14),
      lastSavedAt: DateTime(2026, 11, 15, 22, 40),
      difficulty: CareerDifficulty.realistic,
      cashBalanceEur: 14500000,
      uciPointsSeason: 6820,
      rosterCount: 28,
      fileSizeBytes: 245760,
    ),
    uciRank: 2,
    playTime: const Duration(hours: 12, minutes: 35),
    secondaryColorHex: '#D4AF37',
    teamShortCode: 'AET',
  );

  final slot1 = SaveSlotEnrichedInfo(
    slot: SaveSlotInfo(
      slotNumber: 1,
      slotKey: 'slot_1',
      isOccupied: true,
      isAutoSave: false,
      saveId: 'save_1',
      saveName: 'Kampania Alpejska',
      playerManagerName: 'Jan Kowalski',
      playerTeamId: 'wt_polska',
      playerTeamName: 'Polonia Racing Team',
      playerTeamDivision: 'PRO',
      playerTeamJerseyPrimaryHex: '#EF4444',
      currentSeasonYear: 2026,
      currentDate: DateTime(2026, 5, 20),
      lastSavedAt: DateTime(2026, 11, 15, 20, 15),
      difficulty: CareerDifficulty.normal,
      cashBalanceEur: 4250000,
      uciPointsSeason: 2150,
      rosterCount: 22,
      fileSizeBytes: 184320,
    ),
    uciRank: 11,
    playTime: const Duration(hours: 4, minutes: 10),
    secondaryColorHex: '#FFFFFF',
    teamShortCode: 'POL',
  );

  final emptySlots = List.generate(
    4,
    (index) => SaveSlotEnrichedInfo.fromSlotInfo(SaveSlotInfo.empty(index + 2)),
  );

  return [autoSave, slot1, ...emptySlots];
}

Widget _wrapModal({
  required Widget child,
  required Size size,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SizedBox(
            width: size.width,
            height: size.height,
            child: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SaveLoadSlotsModal', () {
    testWidgets('renders Auto-Save + 5 manual slots with crest and telemetry',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1600, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _wrapModal(
          size: const Size(1600, 900),
          child: SaveLoadSlotsModal(
            initialSlots: _buildMockSlots(),
            activeSlotNumber: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ZARZĄDZANIE ZAPISAMI KARIERY'), findsOneWidget);
      expect(find.text('AUTO-SAVE'), findsOneWidget);
      expect(find.text('SLOT 1'), findsOneWidget);
      expect(find.text('SLOT 5'), findsOneWidget);
      expect(find.text('Auto-Save Tour de France'), findsOneWidget);
      expect(find.text('Kampania Alpejska'), findsOneWidget);
      expect(find.text('#2 • 6820 pkt'), findsOneWidget);
      expect(find.text('12h 35m'), findsOneWidget);
      expect(find.text('2026-07-14'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('responsive layout has zero overflow at 390x844, 1024x768, 1600x900',
        (tester) async {
      for (final size in const [
        Size(390, 844),
        Size(1024, 768),
        Size(1600, 900),
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          _wrapModal(
            size: size,
            child: SaveLoadSlotsModal(
              initialSlots: _buildMockSlots(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('supports load, delete confirmation, and export dialog',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int? loadedSlot;
      int? deletedSlot;
      int? exportedSlot;

      final portableMock = jsonEncode({
        'magicHeader': PortableSavePackage.currentMagicHeader,
        'schemaVersion': 1,
        'exportedAt': DateTime(2026, 11, 15).toIso8601String(),
        'sourcePlatform': 'windows',
        'checksum': '0000000000000000',
        'slotMetadata': _buildMockSlots()[1].slot.toJson(),
        'payloadJsonString': '{}',
      });

      await tester.pumpWidget(
        _wrapModal(
          size: const Size(1280, 800),
          child: SaveLoadSlotsModal(
            initialSlots: _buildMockSlots(),
            onLoadSlot: (slot) async {
              loadedSlot = slot;
              return true;
            },
            onDeleteSlot: (slot) async {
              deletedSlot = slot;
              return true;
            },
            onExportSlotJson: (slot) async {
              exportedSlot = slot;
              return portableMock;
            },
            slotsLoader: () async => _buildMockSlots(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test delete confirmation on first occupied slot (Auto-Save)
      await tester.tap(find.text('Usuń').first);
      await tester.pumpAndSettle();
      expect(find.text('Potwierdź usunięcie'), findsOneWidget);

      await tester.tap(find.text('Potwierdź usunięcie'));
      await tester.pumpAndSettle();
      expect(deletedSlot, 0);

      // Test export dialog
      await tester.tap(find.text('Eksport .json').first);
      await tester.pumpAndSettle();
      expect(exportedSlot, 0);
      expect(find.text('Kopiuj JSON'), findsOneWidget);
      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();

      // Test load slot
      await tester.tap(find.text('Wczytaj').first);
      await tester.pumpAndSettle();
      expect(loadedSlot, 0);
    });
  });
}
