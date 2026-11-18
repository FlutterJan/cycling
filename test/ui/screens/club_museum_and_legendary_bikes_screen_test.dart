import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/equipment_wind_tunnel_custom_decals_and_serials.dart';
import 'package:pro_peloton_manager/ui/screens/club_museum_and_legendary_bikes_screen.dart';

void main() {
  group('ClubMuseumNotifier unit tests', () {
    test('initializes with default exhibits and relics', () {
      final notifier = ClubMuseumNotifier();
      expect(notifier.state.exhibits.length, greaterThanOrEqualTo(5));
      expect(notifier.state.relics.length, greaterThanOrEqualTo(6));
      expect(notifier.state.selectedExhibitId, notifier.state.exhibits.first.id);
      expect(notifier.state.totalHeritageScore, greaterThan(0));
    });

    test('filters by era, category, and search query', () {
      final notifier = ClubMuseumNotifier();
      notifier.setEraFilter(MuseumBikeEra.steelClassic);
      expect(notifier.state.filteredExhibits.length, 1);
      expect(notifier.state.filteredExhibits.first.year, 1974);

      notifier.resetFilters();
      notifier.setCategoryFilter(MuseumExhibitCategory.worldChampion);
      expect(notifier.state.filteredExhibits.length, 1);
      expect(
        notifier.state.filteredExhibits.first.editionType,
        ChampionshipEditionType.worldChampionRainbow,
      );

      notifier.resetFilters();
      notifier.setSearchQuery('Roubaix');
      expect(notifier.state.filteredExhibits.length, 1);
      expect(notifier.state.filteredExhibits.first.year, 2012);
    });

    test('supports polishing exhibit up to 100% and pinning to lobby', () {
      final notifier = ClubMuseumNotifier();
      const targetId = 'exhibit_1974_molteni';
      final initialProgress = notifier.state.restorationProgress[targetId]!;
      expect(initialProgress, lessThan(100));

      notifier.polishExhibit(targetId);
      expect(
        notifier.state.restorationProgress[targetId],
        initialProgress + 15,
      );

      notifier.polishExhibit(targetId);
      notifier.polishExhibit(targetId);
      expect(notifier.state.restorationProgress[targetId], 100);

      notifier.togglePinToLobby(targetId);
      expect(notifier.state.pinnedExhibitIds.contains(targetId), isTrue);
    });

    test('imports serialized museum/gold frames from garage records', () {
      final notifier = ClubMuseumNotifier(
        garageRecords: [
          CustomFrameSerialRecord(
            serialNumber: 'PPM-CUSTOM-2026-999',
            frameModelId: 'aero_proto_x',
            frameModelName: 'Aero Prototype X',
            manufacturerName: 'Apex Cycles',
            assignedRiderId: 'rider_1',
            assignedRiderName: 'Adam Nowak',
            editionType: ChampionshipEditionType.olympicGold,
            finishStyle: DecalFinishStyle.glossMetallicGold,
            status: SerialFrameStatus.museumArchived,
            customTopTubeInscription: 'Złoto Igrzysk 2026',
            nationalFlagCode: 'PL',
            windTunnelCdA: 0.191,
            frameWeightGrams: 760,
            kilometersRidden: 1450,
            victoriesCount: 3,
            grandTourStagesWon: 1,
            monumentsWon: 0,
            commissionedDate: DateTime(2026, 8, 10),
            estimatedCollectorValueEur: 28000,
          ),
        ],
      );

      expect(
        notifier.state.exhibits
            .any((e) => e.serialNumber == 'PPM-CUSTOM-2026-999'),
        isTrue,
      );
    });
  });

  group('ClubMuseumAndLegendaryBikesScreen responsive widget tests', () {
    Future<void> pumpMuseumAtSize(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ClubMuseumAndLegendaryBikesScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('renders cleanly at 390x844 (mobile) without overflow',
        (tester) async {
      await pumpMuseumAtSize(tester, const Size(390, 844));
      expect(find.text('Muzeum Klubowe 3D'), findsOneWidget);
      expect(find.text('Apex SL-R Gold Edition'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1024x768 (tablet) without overflow',
        (tester) async {
      await pumpMuseumAtSize(tester, const Size(1024, 768));
      expect(
        find.text('Muzeum Klubowe & Historyczne Rowery 3D'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly at 1600x900 (desktop) and switches tabs',
        (tester) async {
      await pumpMuseumAtSize(tester, const Size(1600, 900));
      expect(
        find.text('Muzeum Klubowe & Historyczne Rowery 3D'),
        findsOneWidget,
      );
      expect(find.text('Katalog Eksponatów'), findsOneWidget);

      await tester.tap(find.text('Gabloty & Pamiątki'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.text('Gabloty Trofeów & Pamiątki Historyczne'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
