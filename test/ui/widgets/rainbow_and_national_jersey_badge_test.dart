// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/services/career/national_championships_and_worlds_service.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';
import 'package:pro_peloton_manager/ui/widgets/rainbow_and_national_jersey_badge.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_avatar_painter.dart';

void main() {
  group('RainbowAndNationalJerseyBadge Tests', () {
    Rider createTestRider({
      required String id,
      required String firstName,
      required String lastName,
      required String nationalityIso,
    }) {
      final base = RiderProceduralGenerator.generateRider(
        specialization: RiderSpecialization.gcClimber,
        role: RiderRole.teamLeader,
        targetOverallRating: 88,
      );
      return base.copyWith(
        id: id,
        firstName: firstName,
        lastName: lastName,
        nationalityIso: nationalityIso,
      );
    }

    test('UciRainbowColors defines the authentic 5 stripes in correct order', () {
      expect(UciRainbowColors.stripes.length, 5);
      expect(UciRainbowColors.stripes[0], UciRainbowColors.blue);
      expect(UciRainbowColors.stripes[1], UciRainbowColors.red);
      expect(UciRainbowColors.stripes[2], UciRainbowColors.black);
      expect(UciRainbowColors.stripes[3], UciRainbowColors.yellow);
      expect(UciRainbowColors.stripes[4], UciRainbowColors.green);
      expect(UciRainbowColors.rainbowGradient.colors.length, 5);
    });

    testWidgets('Standard team jersey badge renders SizedBox.shrink', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RainbowAndNationalJerseyBadge(
              designation: SpecialJerseyDesignation.standardTeamJersey,
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(RainbowJerseyStripesBar), findsNothing);
    });

    testWidgets('Rainbow jersey renders in tableCompact and ribbonPill styles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RainbowAndNationalJerseyBadge.rainbow(
                  style: BadgeStyle.tableCompact,
                  size: 22.0,
                ),
                RainbowAndNationalJerseyBadge.rainbow(
                  style: BadgeStyle.ribbonPill,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(RainbowJerseyStripesBar), findsNWidgets(2));
      expect(find.text('MISTRZ ŚWIATA UCI'), findsOneWidget);
    });

    testWidgets('National champion badge renders with country colors', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RainbowAndNationalJerseyBadge.national(
                  countryIso: 'POL',
                  style: BadgeStyle.ribbonPill,
                ),
                RainbowAndNationalJerseyBadge.national(
                  countryIso: 'FRA',
                  style: BadgeStyle.tableCompact,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('MISTRZ: POLSKA'), findsOneWidget);
      expect(find.byType(NationalJerseyStripesBar), findsNWidgets(2));
    });

    testWidgets('Former world champion renders WC cuffs tag and sleeve badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RainbowAndNationalJerseyBadge.formerWorldChampion(
                  style: BadgeStyle.tableCompact,
                ),
                RainbowAndNationalJerseyBadge.formerWorldChampion(
                  style: BadgeStyle.ribbonPill,
                ),
                RainbowAndNationalJerseyBadge.formerWorldChampion(
                  style: BadgeStyle.sleeveCuffTag,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('WC'), findsOneWidget);
      expect(find.text('B. MISTRZ ŚWIATA (PASKI NA RĘKAWKACH)'), findsOneWidget);
      expect(find.text('RAINBOW CUFFS'), findsOneWidget);
    });

    testWidgets('fromRider factory auto-resolves jersey hierarchy via ReigningChampionsRegistry', (WidgetTester tester) async {
      final registry = ReigningChampionsRegistry();
      final worldChamp = createTestRider(id: 'r-1', firstName: 'Tadej', lastName: 'Pogačar', nationalityIso: 'SLO');
      final polandChamp = createTestRider(id: 'r-2', firstName: 'Michał', lastName: 'Kwiatkowski', nationalityIso: 'POL');
      final formerChamp = createTestRider(id: 'r-3', firstName: 'Julian', lastName: 'Alaphilippe', nationalityIso: 'FRA');
      final regularRider = createTestRider(id: 'r-4', firstName: 'Rafał', lastName: 'Majka', nationalityIso: 'POL');

      // Register reigning world champion
      registry.registerWorldChampion(ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.world,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'WORLD',
        winnerRiderId: 'r-1',
        winnerRiderName: 'Tadej Pogačar',
        winningTradeTeamName: 'UAE',
        dateAwarded: DateTime(2026, 9, 27),
        uciPointsAwarded: 900,
      ));

      // Register Poland national champion
      registry.registerNationalChampion(ChampionshipTitle(
        year: 2026,
        level: ChampionshipLevel.national,
        discipline: ChampionshipDiscipline.roadRace,
        countryIso: 'POL',
        winnerRiderId: 'r-2',
        winnerRiderName: 'Michał Kwiatkowski',
        winningTradeTeamName: 'Ineos',
        dateAwarded: DateTime(2026, 6, 28),
        uciPointsAwarded: 100,
      ));

      // Former champion who lost his rainbow tenure
      registry.lifetimeWorldChampionRiderIds.add('r-3');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RainbowAndNationalJerseyBadge.fromRider(
                  rider: worldChamp,
                  registry: registry,
                  style: BadgeStyle.ribbonPill,
                ),
                RainbowAndNationalJerseyBadge.fromRider(
                  rider: polandChamp,
                  registry: registry,
                  style: BadgeStyle.ribbonPill,
                ),
                RainbowAndNationalJerseyBadge.fromRider(
                  rider: formerChamp,
                  registry: registry,
                  style: BadgeStyle.ribbonPill,
                ),
                RainbowAndNationalJerseyBadge.fromRider(
                  rider: regularRider,
                  registry: registry,
                  style: BadgeStyle.ribbonPill,
                ),
              ],
            ),
          ),
        ),
      );

      // Check displayed badges
      expect(find.text('MISTRZ ŚWIATA UCI'), findsOneWidget);
      expect(find.text('MISTRZ: POLSKA'), findsOneWidget);
      expect(find.text('B. MISTRZ ŚWIATA (PASKI NA RĘKAWKACH)'), findsOneWidget);
      // regularRider renders SizedBox.shrink
      expect(find.text('MISTRZ: RAFAŁ'), findsNothing);
    });

    testWidgets('Jersey miniature paints properly for rainbow, national, and former champion', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                RainbowAndNationalJerseyBadge.rainbow(style: BadgeStyle.jerseyMiniature, size: 40.0),
                RainbowAndNationalJerseyBadge.national(countryIso: 'ITA', style: BadgeStyle.jerseyMiniature, size: 40.0),
                RainbowAndNationalJerseyBadge.formerWorldChampion(style: BadgeStyle.jerseyMiniature, size: 40.0),
              ],
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(RainbowAndNationalJerseyBadge),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('Avatar corner pill badge renders in stack over avatar', (WidgetTester tester) async {
      final rider = createTestRider(id: 'tadej-1', firstName: 'Tadej', lastName: 'Pogačar', nationalityIso: 'SLO');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RiderChampionshipAvatar(
              rider: rider,
              manualDesignation: SpecialJerseyDesignation.rainbowJersey,
              size: 80.0,
            ),
          ),
        ),
      );

      expect(find.byType(RiderAvatarWidget), findsOneWidget);
      expect(find.byType(RainbowAndNationalJerseyBadge), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RiderChampionshipAvatar),
          matching: find.byType(Stack),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tap interaction fires callback', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RainbowAndNationalJerseyBadge.rainbow(
              style: BadgeStyle.ribbonPill,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(RainbowAndNationalJerseyBadge));
      expect(tapped, isTrue);
    });

    test('Championship3DVisuals resolves colors and renders 3D accents', () {
      const defaultTeam = Color(0xFF1E3A8A);

      final rainbowColor = Championship3DVisuals.resolve3DPrimaryJerseyColor(
        designation: SpecialJerseyDesignation.rainbowJersey,
        defaultTeamColor: defaultTeam,
      );
      expect(rainbowColor, Colors.white);

      final polandColor = Championship3DVisuals.resolve3DPrimaryJerseyColor(
        designation: SpecialJerseyDesignation.nationalChampionJersey,
        countryIso: 'POL',
        defaultTeamColor: defaultTeam,
      );
      expect(polandColor, Colors.white);

      final formerColor = Championship3DVisuals.resolve3DPrimaryJerseyColor(
        designation: SpecialJerseyDesignation.formerWorldChampionRainbowBands,
        defaultTeamColor: defaultTeam,
      );
      expect(formerColor, defaultTeam);

      // Verify painting accents executes without error
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const rect = Rect.fromLTWH(0, 0, 40, 60);

      Championship3DVisuals.paint3DChampionshipAccents(
        canvas: canvas,
        designation: SpecialJerseyDesignation.rainbowJersey,
        torsoRect: rect,
        scale: 1.0,
      );

      Championship3DVisuals.paint3DChampionshipAccents(
        canvas: canvas,
        designation: SpecialJerseyDesignation.formerWorldChampionRainbowBands,
        torsoRect: rect,
        scale: 1.0,
        leftWrist: const Offset(5, 50),
        rightWrist: const Offset(35, 50),
      );

      Championship3DVisuals.paint3DChampionshipAccents(
        canvas: canvas,
        designation: SpecialJerseyDesignation.nationalChampionJersey,
        torsoRect: rect,
        scale: 1.0,
        countryIso: 'FRA',
      );

      final picture = recorder.endRecording();
      expect(picture, isNotNull);
    });
  });
}
