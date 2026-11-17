import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/screens/legends_card_album_and_packs_screen.dart';

void main() {
  group('LegendsCardAlbumNotifier & Models Unit Tests', () {
    test('AlbumLegendCardEntry and PendingChampionshipPack serialize to/from JSON',
        () {
      final entry = LegendsAlbumCatalog.buildDefaultEntries().first;
      final restoredEntry = AlbumLegendCardEntry.fromJson(entry.toJson());
      expect(restoredEntry.riderId, entry.riderId);
      expect(restoredEntry.era, entry.era);
      expect(restoredEntry.teamGroup, entry.teamGroup);
      expect(restoredEntry.unlockSource, entry.unlockSource);
      expect(restoredEntry.isUnlocked, entry.isUnlocked);

      final pack = LegendsAlbumCatalog.buildDefaultPendingPacks().first;
      final restoredPack = PendingChampionshipPack.fromJson(pack.toJson());
      expect(restoredPack.packId, pack.packId);
      expect(restoredPack.tier, pack.tier);
      expect(restoredPack.cardCount, pack.cardCount);
      expect(restoredPack.isOpened, pack.isOpened);
    });

    test('openPack unlocks guaranteed high-OVR card and marks pack opened', () {
      final notifier = LegendsCardAlbumNotifier(random: math.Random(42));
      final initialUnlocked = notifier.state.unlockedCards;
      final pack = notifier.state.unopenedPacks.first;

      final result = notifier.openPack(pack.packId);

      expect(result.pulledCards.length, pack.cardCount);
      expect(
        result.pulledCards.any(
          (p) => p.entry.cardData.ovr >= pack.tier.guaranteedMinOvr,
        ),
        isTrue,
      );
      expect(notifier.state.unlockedCards, greaterThan(initialUnlocked));
      expect(notifier.state.unopenedPacks, isEmpty);
    });

    test('awardWorldTourVictoryPack adds unopened pack and increments wins',
        () {
      final notifier = LegendsCardAlbumNotifier();
      final winsBefore = notifier.state.worldTourWinsCount;
      final packsBefore = notifier.state.unopenedPacks.length;

      final awarded = notifier.awardWorldTourVictoryPack(
        raceName: 'Giro d\'Italia',
      );

      expect(notifier.state.worldTourWinsCount, winsBefore + 1);
      expect(notifier.state.unopenedPacks.length, packsBefore + 1);
      expect(awarded.originRaceName, contains('Giro d\'Italia'));
    });

    test('unlockCardDirectly unlocks new card and counts duplicates on repeat',
        () {
      final notifier = LegendsCardAlbumNotifier();
      const targetId = 'wt_vingegaard_26';

      notifier.unlockCardDirectly(
        targetId,
        sourceOverride: CardUnlockSource.tacticalChallenge,
      );
      var target = notifier.state.entries.firstWhere(
        (e) => e.riderId == targetId,
      );
      expect(target.isUnlocked, isTrue);
      expect(target.unlockSource, CardUnlockSource.tacticalChallenge);
      expect(target.duplicateCount, 0);

      notifier.unlockCardDirectly(targetId);
      target = notifier.state.entries.firstWhere(
        (e) => e.riderId == targetId,
      );
      expect(target.duplicateCount, 1);
    });

    test('filters and search query narrow album entries accurately', () {
      final notifier = LegendsCardAlbumNotifier();
      notifier.setFilterMode(LegendsAlbumFilterMode.goldLegendsOnly);
      expect(
        notifier.state.filteredEntries.every((e) => e.cardData.ovr >= 90),
        isTrue,
      );

      notifier.setFilterMode(LegendsAlbumFilterMode.all);
      notifier.setSearchQuery('Polonia');
      expect(notifier.state.filteredEntries.length, 1);
      expect(
        notifier.state.filteredEntries.first.riderId,
        'leg_szurkowski_73',
      );
    });
  });

  group('LegendsCardAlbumAndPacksScreen Responsive Widget Tests', () {
    Future<void> pumpAtSize(
      WidgetTester tester,
      Size size, {
      VoidCallback? onAfterPump,
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: LegendsCardAlbumAndPacksScreen(
            enableAmbientShimmer: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      onAfterPump?.call();
    }

    testWidgets('renders without overflow on 390x844 mobile', (tester) async {
      await pumpAtSize(tester, const Size(390, 844));
      expect(find.text('ALBUM KART I GWIAZD'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('open_golden_pack_button')),
        findsOneWidget,
      );
    });

    testWidgets('renders without overflow on 1024x768 tablet', (tester) async {
      await pumpAtSize(tester, const Size(1024, 768));
      expect(find.text('ALBUM KART I KOLEKCJA GWIAZD'), findsOneWidget);
    });

    testWidgets('renders without overflow on 1600x900 desktop with inspector',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));
      expect(find.text('ALBUM KART I KOLEKCJA GWIAZD'), findsOneWidget);
      expect(find.text('INSPEKTOR KARTY'), findsOneWidget);
    });

    testWidgets('switches grouping between Epoki and Drużyny and filters',
        (tester) async {
      await pumpAtSize(tester, const Size(1600, 900));

      expect(find.text('Złote Lata 70. (1970–1984)'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('grouping_byTeam')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Molteni Heritage'), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('filter_unlockedOnly')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens Złota Paczka Mistrzowska, reveals cards, and collects',
        (tester) async {
      await pumpAtSize(tester, const Size(1280, 860));

      await tester.tap(find.byKey(const ValueKey('open_golden_pack_button')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ZŁOTA PACZKA MISTRZOWSKA'), findsOneWidget);

      // Advance pack animation to card reveal
      await tester.pump(const Duration(milliseconds: 1400));
      expect(find.text('NOWA KARTA!'), findsWidgets);

      await tester.tap(
        find.byKey(const ValueKey('collect_pack_cards_button')),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Brak oczekujących Paczek Mistrzowskich'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
