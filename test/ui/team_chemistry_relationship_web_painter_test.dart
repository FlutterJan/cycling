import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/career/rider_relationship_chemistry_web_model.dart';
import 'package:pro_peloton_manager/ui/widgets/team_chemistry_relationship_web_painter.dart';

RiderRelationshipChemistryWebModel _buildSampleChemistryModel() {
  const roster = <RiderLockerRoomProfile>[
    RiderLockerRoomProfile(
      riderId: 'r1',
      riderName: 'Tadej Kowalski',
      archetype: LockerRoomPersonalityArchetype.alphaLeader,
      leadershipWeight: 92,
      egoLevel: 82,
      adaptability: 68,
      currentMorale: 88,
      isTeamCaptain: true,
    ),
    RiderLockerRoomProfile(
      riderId: 'r2',
      riderName: 'Jan Nowak',
      archetype: LockerRoomPersonalityArchetype.humbleDomestique,
      leadershipWeight: 65,
      egoLevel: 25,
      adaptability: 86,
      currentMorale: 84,
    ),
    RiderLockerRoomProfile(
      riderId: 'r3',
      riderName: 'Marek Zielinski',
      archetype: LockerRoomPersonalityArchetype.ambitiousWonderkid,
      leadershipWeight: 54,
      egoLevel: 88,
      adaptability: 45,
      currentMorale: 62,
    ),
    RiderLockerRoomProfile(
      riderId: 'r4',
      riderName: 'Piotr Wisniewski',
      archetype: LockerRoomPersonalityArchetype.lockerRoomJoker,
      leadershipWeight: 60,
      egoLevel: 35,
      adaptability: 92,
      currentMorale: 91,
    ),
    RiderLockerRoomProfile(
      riderId: 'r5',
      riderName: 'Adam Kaminski',
      archetype: LockerRoomPersonalityArchetype.mentorVeteran,
      leadershipWeight: 80,
      egoLevel: 40,
      adaptability: 88,
      currentMorale: 79,
    ),
  ];

  final base = RiderRelationshipChemistryWebModel.fromRoster(
    teamId: 'team_1',
    seasonYear: 2026,
    roster: roster,
  );

  final customEdges = Map<String, RiderRelationshipEdge>.from(base.edges);
  // Złoty pakt Blood Brothers: r1 <-> r2
  customEdges[RiderRelationshipEdge.canonicalPairKey('r1', 'r2')] =
      const RiderRelationshipEdge(
    riderAId: 'r1',
    riderBId: 'r2',
    score: 94,
    trust: 96,
    respect: 94,
    tension: 4,
    sharedRacesCount: 14,
    lastInteractionReason: 'Wspólna obrona żółtej koszulki w Alpach',
    bloodBrothersPactId: 'bb_r1_r2_2026',
  );
  // Zielone zaufanie: r1 <-> r4
  customEdges[RiderRelationshipEdge.canonicalPairKey('r1', 'r4')] =
      const RiderRelationshipEdge(
    riderAId: 'r1',
    riderBId: 'r4',
    score: 52,
    trust: 74,
    respect: 72,
    tension: 10,
    sharedRacesCount: 8,
    lastInteractionReason: 'Dobra atmosfera na zgrupowaniu',
  );
  // Czerwony konflikt: r1 <-> r3
  customEdges[RiderRelationshipEdge.canonicalPairKey('r1', 'r3')] =
      const RiderRelationshipEdge(
    riderAId: 'r1',
    riderBId: 'r3',
    score: -68,
    trust: 18,
    respect: 32,
    tension: 86,
    sharedRacesCount: 4,
    lastInteractionReason: 'Spór o rolę lidera na etapie górskim',
  );

  const pact = BloodBrothersPact(
    pactId: 'bb_r1_r2_2026',
    riderAId: 'r1',
    riderBId: 'r2',
    formedDateIso: '2026-07-14',
    formedAtRaceName: 'Tour de France',
    status: BloodBrothersPactStatus.active,
    loyaltyStrength: 95,
    sharedTriumphsCount: 3,
    selflessSacrificeCount: 2,
  );

  return RiderRelationshipChemistryWebModel(
    teamId: base.teamId,
    seasonYear: base.seasonYear,
    profiles: base.profiles,
    edges: Map<String, RiderRelationshipEdge>.unmodifiable(customEdges),
    bloodBrothersPacts: const <BloodBrothersPact>[pact],
    recentEvents: base.recentEvents,
  );
}

void main() {
  group('TeamChemistryWebLayoutCalculator', () {
    test('wylicza węzły na okręgu i obsługuje pusty model oraz 1 kolarza', () {
      final emptyModel = RiderRelationshipChemistryWebModel.empty(
        teamId: 'empty',
        seasonYear: 2026,
      );
      expect(
        TeamChemistryWebLayoutCalculator.computeNodeLayouts(
          model: emptyModel,
          size: const Size(360, 360),
        ),
        isEmpty,
      );

      final singleModel = RiderRelationshipChemistryWebModel.fromRoster(
        teamId: 'single',
        seasonYear: 2026,
        roster: const <RiderLockerRoomProfile>[
          RiderLockerRoomProfile(
            riderId: 'solo',
            riderName: 'Solo Rider',
            archetype: LockerRoomPersonalityArchetype.silentProfessional,
            leadershipWeight: 50,
            egoLevel: 50,
            adaptability: 50,
            currentMorale: 75,
          ),
        ],
      );
      final singleNodes = TeamChemistryWebLayoutCalculator.computeNodeLayouts(
        model: singleModel,
        size: const Size(300, 300),
      );
      expect(singleNodes, hasLength(1));
      expect(singleNodes.first.center, const Offset(150, 150));
    });

    test('filtruje złote, zielone i czerwone krawędzie oraz wspiera hitTest', () {
      final model = _buildSampleChemistryModel();
      const canvasSize = Size(400, 400);
      final nodes = TeamChemistryWebLayoutCalculator.computeNodeLayouts(
        model: model,
        size: canvasSize,
      );
      expect(nodes, hasLength(5));
      expect(nodes.first.riderId, 'r1'); // Kapitan na początku

      final goldEdges = TeamChemistryWebLayoutCalculator.computeVisibleEdges(
        model: model,
        nodes: nodes,
        size: canvasSize,
        filter: RelationshipWebToneFilter.goldOnly,
      );
      expect(goldEdges, hasLength(1));
      expect(goldEdges.first.tone, RelationshipConnectionVisualTone.gold);

      final conflictEdges = TeamChemistryWebLayoutCalculator.computeVisibleEdges(
        model: model,
        nodes: nodes,
        size: canvasSize,
        filter: RelationshipWebToneFilter.conflictsOnly,
      );
      expect(conflictEdges, hasLength(1));
      expect(conflictEdges.first.tone, RelationshipConnectionVisualTone.red);

      final hitNode = TeamChemistryWebLayoutCalculator.hitTestNode(
        position: nodes.first.center,
        nodes: nodes,
      );
      expect(hitNode?.riderId, nodes.first.riderId);

      final midGold = goldEdges.first.pointAt(0.5);
      final hitEdge = TeamChemistryWebLayoutCalculator.hitTestEdge(
        position: midGold,
        edges: goldEdges,
      );
      expect(hitEdge?.edge.pairKey, goldEdges.first.edge.pairKey);
    });
  });

  group('TeamChemistryRelationshipWebWidget', () {
    for (final viewport in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renderuje bez przepełnień w rozdzielczości ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          final model = _buildSampleChemistryModel();
          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.darkTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: TeamChemistryRelationshipWebWidget(
                    model: model,
                  ),
                ),
              ),
            ),
          );

          await tester.pump(const Duration(milliseconds: 300));

          expect(find.text('Sieć Relacji Szatni'), findsOneWidget);
          expect(find.text('Blood Brothers'), findsWidgets);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('obsługuje filtry, wybór kolarza oraz stan disabled i pusty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      RiderLockerRoomProfile? selectedProfile;
      final model = _buildSampleChemistryModel();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeamChemistryRelationshipWebWidget(
                model: model,
                onRiderSelected: (profile) => selectedProfile = profile,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Kliknięcie filtra Konflikty
      await tester.tap(find.text('Konflikty'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(tester.takeException(), isNull);

      // Kliknięcie węzła na canvasie (górny środek okręgu dla kapitana)
      final paintFinder = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint && w.painter is TeamChemistryRelationshipWebPainter,
      );
      expect(paintFinder, findsOneWidget);
      final paintRect = tester.getRect(paintFinder);
      final nodes = TeamChemistryWebLayoutCalculator.computeNodeLayouts(
        model: model,
        size: paintRect.size,
      );
      await tester.tapAt(paintRect.topLeft + nodes.first.center);
      await tester.pump(const Duration(milliseconds: 250));

      expect(selectedProfile?.riderId, 'r1');
      expect(find.text('Tadej Kowalski'), findsOneWidget);

      // Stan disabled nie wywołuje callbacku
      selectedProfile = null;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: TeamChemistryRelationshipWebWidget(
                model: model,
                enabled: false,
                onRiderSelected: (profile) => selectedProfile = profile,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tapAt(paintRect.topLeft + nodes.first.center);
      await tester.pump(const Duration(milliseconds: 250));
      expect(selectedProfile, isNull);

      // Stan pusty
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: TeamChemistryRelationshipWebWidget(
              model: RiderRelationshipChemistryWebModel.empty(
                teamId: 'empty',
                seasonYear: 2026,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Brak kolarzy w sieci relacji szatni'), findsOneWidget);
    });
  });
}
