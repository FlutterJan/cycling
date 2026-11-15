import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/podium_3d_ceremony_painter.dart';

void main() {
  const List<PodiumRiderEntry> samplePodium = <PodiumRiderEntry>[
    PodiumRiderEntry(
      position: 1,
      riderName: 'Michał Kwiatkowski',
      teamName: 'Biało-Czerwoni WT',
      nationalityCode: 'POL',
      timeOrGap: '4h 12\' 18"',
      teamColor: Color(0xFFDC2626),
      jerseyType: PodiumLeaderJerseyType.yellow,
      isPlayerTeam: true,
    ),
    PodiumRiderEntry(
      position: 2,
      riderName: 'Tadej Pogačar',
      teamName: 'Emirates Pro',
      nationalityCode: 'SLO',
      timeOrGap: '+0\' 12"',
      teamColor: Color(0xFF10B981),
      jerseyType: PodiumLeaderJerseyType.polkaDot,
    ),
    PodiumRiderEntry(
      position: 3,
      riderName: 'Jasper Philipsen',
      teamName: 'Alpecin Aero',
      nationalityCode: 'BEL',
      timeOrGap: '+0\' 24"',
      teamColor: Color(0xFF38BDF8),
      jerseyType: PodiumLeaderJerseyType.green,
    ),
  ];

  Widget buildTestHost(Size size, {List<PodiumRiderEntry> riders = samplePodium}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Podium3dCeremonyWidget(
              podiumRiders: riders,
              raceTheme: PodiumCeremonyRaceTheme.tourDeFrance,
              stageTitle: 'Etap 15: Alpe d\'Huez',
            ),
          ),
        ),
      ),
    );
  }

  group('Podium3dCeremonyPainter & Podium3dCeremonyWidget', () {
    testWidgets('renders without overflow on 390x844, 1024x768, and 1600x900', (
      WidgetTester tester,
    ) async {
      final List<Size> viewports = <Size>[
        const Size(390, 844),
        const Size(1024, 768),
        const Size(1600, 900),
      ];

      for (final Size viewport in viewports) {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(buildTestHost(viewport));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(Podium3dCeremonyWidget), findsOneWidget);
        expect(find.text('Mazurek Dąbrowskiego (Michał Kwiatkowski)'), findsOneWidget);
        expect(find.text('Żółta (GC)'), findsOneWidget);
        expect(find.text('Zielona (Punkty)'), findsOneWidget);
        expect(find.text('W Grochy (KOM)'), findsOneWidget);
        expect(find.text('Biała (Młodzież)'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      addTearDown(tester.view.resetPhysicalSize);
    });

    testWidgets('handles empty podium list gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestHost(const Size(1024, 768), riders: const <PodiumRiderEntry>[]));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Brak sklasyfikowanych kolarzy na podium etapu.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('interactive jersey toggles, confetti, flash burst, and anthem pause work', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestHost(const Size(1200, 800)));
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('W Grochy (KOM)'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Konfetti'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Flesze'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Pauza'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Hymn'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    test('PodiumNationalAnthemProfile resolves known and fallback countries with valid PCM', () {
      final PodiumNationalAnthemProfile pol = PodiumNationalAnthemProfile.forCountry('pol');
      expect(pol.anthemTitle, 'Mazurek Dąbrowskiego');
      final Uint8List pcm = pol.synthesizePreviewPcm();
      expect(pcm.length, greaterThan(1000));

      final PodiumNationalAnthemProfile unknown = PodiumNationalAnthemProfile.forCountry('XYZ');
      expect(unknown.anthemTitle, 'Hymn Narodowy (XYZ)');
      expect(unknown.synthesizePreviewPcm().length, greaterThan(1000));
    });
  });
}
