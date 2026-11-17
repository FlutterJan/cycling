import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/transfer_rumor_mill_and_journalists_service.dart';
import 'package:pro_peloton_manager/ui/widgets/cycling_media_social_feed_panel.dart';

void main() {
  final defaultJournalists =
      TransferRumorMillAndJournalistsService.createDefaultJournalists();

  TransferRumor makeRumor({
    required String id,
    required String riderName,
    RumorVeracityTier veracity = RumorVeracityTier.credible,
    RumorStatus status = RumorStatus.active,
    RumorActionType playerResponse = RumorActionType.none,
    bool isPlayerTeamInvolved = true,
    bool isSmokescreen = false,
    int credibility = 82,
    int marketHeatDelta = 12,
    DateTime? createdDate,
  }) {
    final created = createdDate ?? DateTime(2026, 7, 14);
    final journalist = defaultJournalists.first;
    return TransferRumor(
      id: id,
      targetRiderId: 'rider_$id',
      targetRiderName: riderName,
      targetRiderRole: RiderRole.teamLeader,
      sourceTeamId: 'team_src',
      sourceTeamName: 'Team Alpecin',
      rumoredDestinationTeamId: 'player_team',
      rumoredDestinationTeamName: 'Pro Peloton Racing',
      journalistId: journalist.id,
      journalistName: journalist.name,
      journalistHandle: journalist.handle,
      credibilityAtPublish: credibility,
      veracity: veracity,
      status: status,
      playerResponse: playerResponse,
      headline: '$riderName łączony z transferem do Pro Peloton Racing',
      body: 'Według źródeł z peletonu trwają zaawansowane rozmowy kontraktowe.',
      createdDate: created,
      expiresDate: created.add(const Duration(days: 7)),
      isPlayerTeamInvolved: isPlayerTeamInvolved,
      isSmokescreen: isSmokescreen,
      estimatedSalaryEur: 2400000,
      marketHeatDelta: marketHeatDelta,
    );
  }

  TransferRumorMillState makeSampleState() {
    return TransferRumorMillState(
      journalists: defaultJournalists,
      activeRumors: [
        makeRumor(
          id: 'r1',
          riderName: 'Jan Kowalski',
          veracity: RumorVeracityTier.confirmedLeak,
          credibility: 91,
          marketHeatDelta: 15,
          createdDate: DateTime(2026, 7, 15),
        ),
        makeRumor(
          id: 'r2',
          riderName: 'Marcin Nowak',
          veracity: RumorVeracityTier.smokescreen,
          isSmokescreen: true,
          credibility: 55,
          marketHeatDelta: 8,
          createdDate: DateTime(2026, 7, 13),
        ),
      ],
      archivedRumors: [
        makeRumor(
          id: 'r3',
          riderName: 'Piotr Zieliński',
          status: RumorStatus.denied,
          playerResponse: RumorActionType.deny,
          credibility: 74,
          marketHeatDelta: 5,
          createdDate: DateTime(2026, 7, 10),
        ),
      ],
      smokescreens: const [],
      moraleHistory: [
        MoraleImpactEntry(
          riderId: 'rider_sq_1',
          riderName: 'Adam Wiśniewski',
          riderRole: RiderRole.teamLeader,
          deltaMorale: -4.5,
          deltaLoyalty: -2.0,
          reason: 'Niepokój przed konkurencją na pozycji lidera GC',
          triggeredByRumorId: 'r1',
          date: DateTime(2026, 7, 15),
        ),
      ],
      mediaCredibilityScore: 78,
      marketHeatIndex: 64,
      lastTickDate: DateTime(2026, 7, 15),
    );
  }

  group('CyclingMediaSocialFeedCalculator', () {
    test('builds posts, filters, sorts and summarizes state', () {
      final state = makeSampleState();
      final posts = CyclingMediaSocialFeedCalculator.buildPosts(state);
      expect(posts.length, 3);

      final actionable = CyclingMediaSocialFeedCalculator.filterAndSort(
        posts: posts,
        filter: CyclingMediaFeedFilter.actionable,
        sortOrder: CyclingMediaSortOrder.newestFirst,
      );
      expect(actionable.length, 2);
      expect(actionable.first.rumor.id, 'r1');

      final smokescreens = CyclingMediaSocialFeedCalculator.filterAndSort(
        posts: posts,
        filter: CyclingMediaFeedFilter.smokescreens,
        sortOrder: CyclingMediaSortOrder.newestFirst,
      );
      expect(smokescreens.length, 1);
      expect(smokescreens.first.rumor.id, 'r2');

      final resolved = CyclingMediaSocialFeedCalculator.filterAndSort(
        posts: posts,
        filter: CyclingMediaFeedFilter.resolved,
        sortOrder: CyclingMediaSortOrder.newestFirst,
      );
      expect(resolved.length, 1);
      expect(resolved.first.rumor.id, 'r3');

      final searched = CyclingMediaSocialFeedCalculator.filterAndSort(
        posts: posts,
        filter: CyclingMediaFeedFilter.all,
        sortOrder: CyclingMediaSortOrder.highestHeat,
        searchQuery: 'Nowak',
      );
      expect(searched.length, 1);
      expect(searched.first.rumor.targetRiderName, 'Marcin Nowak');

      final summary = CyclingMediaSocialFeedCalculator.summarize(state);
      expect(summary.totalPosts, 3);
      expect(summary.activeLeaksCount, 2);
      expect(summary.actionableCount, 2);
      expect(summary.smokescreenCount, 1);
      expect(summary.pressureLabel, 'Gorący Rynek');
    });

    test('CyclingMediaFeedPost JSON round-trip preserves fields', () {
      final state = makeSampleState();
      final post = CyclingMediaSocialFeedCalculator.buildPosts(state).first;
      final json = post.toJson();
      final restored = CyclingMediaFeedPost.fromJson(json);

      expect(restored.rumor.id, post.rumor.id);
      expect(restored.affiliation, post.affiliation);
      expect(restored.likesCount, post.likesCount);
      expect(restored.repostsCount, post.repostsCount);
      expect(restored.repliesCount, post.repliesCount);
      expect(restored.hashtag, post.hashtag);
      expect(restored.isBreaking, post.isBreaking);
    });
  });

  group('CyclingMediaSocialFeedPanel widget tests', () {
    Widget wrapWithSize(Widget child, Size size) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders empty state when no rumors are present', (tester) async {
      await tester.pumpWidget(
        wrapWithSize(
          CyclingMediaSocialFeedPanel(
            stateOverride: TransferRumorMillState.initial(),
          ),
          const Size(1024, 768),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Brak doniesień prasowych dla wybranego filtra'),
        findsOneWidget,
      );
    });

    testWidgets('deny and confirm buttons invoke callbacks when actionable',
        (tester) async {
      TransferRumor? capturedRumor;
      RumorActionType? capturedAction;

      await tester.pumpWidget(
        wrapWithSize(
          CyclingMediaSocialFeedPanel(
            stateOverride: makeSampleState(),
            onRumorAction: (rumor, action) {
              capturedRumor = rumor;
              capturedAction = action;
            },
          ),
          const Size(1280, 860),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final denyButton = find.byKey(const ValueKey('deny_rumor_r1'));
      expect(denyButton, findsOneWidget);
      await tester.ensureVisible(denyButton);
      await tester.tap(denyButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedRumor?.id, 'r1');
      expect(capturedAction, RumorActionType.deny);

      final confirmButton = find.byKey(const ValueKey('confirm_rumor_r2'));
      expect(confirmButton, findsOneWidget);
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(capturedRumor?.id, 'r2');
      expect(capturedAction, RumorActionType.confirm);
    });

    testWidgets('isReadOnly disables rumor action buttons', (tester) async {
      var called = false;

      await tester.pumpWidget(
        wrapWithSize(
          CyclingMediaSocialFeedPanel(
            stateOverride: makeSampleState(),
            isReadOnly: true,
            onRumorAction: (_, __) => called = true,
          ),
          const Size(1280, 860),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tylko podgląd'), findsOneWidget);
      final denyButton = find.byKey(const ValueKey('deny_rumor_r1'));
      await tester.ensureVisible(denyButton);
      await tester.tap(denyButton);
      await tester.pump(const Duration(milliseconds: 300));

      expect(called, isFalse);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await tester.pumpWidget(
            wrapWithSize(
              CyclingMediaSocialFeedPanel(
                stateOverride: makeSampleState(),
              ),
              size,
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Media Kolarskie & Przecieki'), findsOneWidget);
          expect(
            find.text('Jan Kowalski łączony z transferem do Pro Peloton Racing'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
