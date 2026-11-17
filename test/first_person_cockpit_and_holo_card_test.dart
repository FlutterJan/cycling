import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/engine/rendering3d/first_person_cockpit_camera_renderer.dart';
import 'package:pro_peloton_manager/engine/rendering3d/on_bike_computer_hud_widget.dart';
import 'package:pro_peloton_manager/services/career/national_championships_and_worlds_service.dart';
import 'package:pro_peloton_manager/ui/widgets/collectible_pro_rider_holo_card.dart';

Widget _buildTestHost({
  required Size size,
  required Widget child,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: child,
      ),
    ),
  );
}

CollectibleProRiderCardData _createSampleCardData({
  required String riderId,
  required String fullName,
  required int ovr,
  List<GrandTourWinBadge> grandTourWins = const <GrandTourWinBadge>[],
  SpecialJerseyDesignation specialJersey =
      SpecialJerseyDesignation.standardTeamJersey,
}) {
  return CollectibleProRiderCardData(
    riderId: riderId,
    fullName: fullName,
    shortRoleLabel: 'GC / CLIMB',
    nationalityIso: 'SI',
    teamName: 'UAE Team Emirates',
    teamShortCode: 'UAD',
    ovr: ovr,
    editionYear: 2026,
    cardSerialNumber: '01/99',
    stats: const ProRiderCardStats(
      mon: 91,
      hil: 95,
      itt: 89,
      spr: 82,
      cob: 84,
      rec: 94,
    ),
    grandTourWins: grandTourWins,
    specialJersey: specialJersey,
    primaryJerseyColorHex: '#1F2937',
    secondaryJerseyColorHex: '#D4AF37',
    accentJerseyColorHex: '#EF4444',
  );
}

void main() {
  group('FirstPersonCockpitViewportWidget', () {
    const List<Size> responsiveSizes = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final Size viewportSize in responsiveSizes) {
      testWidgets(
        'renderuje kamerę First-Person Cockpit 3D bez błędów układu na ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            _buildTestHost(
              size: viewportSize,
              child: const FirstPersonCockpitViewportWidget(),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(FirstPersonCockpitViewportWidget), findsOneWidget);
          expect(find.byType(CustomPaint), findsWidgets);

          final bool isCompact = viewportSize.width < 540;
          expect(
            find.text(isCompact ? 'COCKPIT 3D' : 'PRO CYCLIST COCKPIT 3D'),
            findsOneWidget,
          );
          expect(find.textContaining('KOŁO PRZED TOBĄ:'), findsOneWidget);
          expect(find.text('Bieg - (L)'), findsOneWidget);
          expect(find.text('Bieg + (R)'), findsOneWidget);

          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    testWidgets(
      'obsługuje interakcje zmiany chwytu, biegów, licznika i gęstości peletonu bez błędów',
      (WidgetTester tester) async {
        const Size desktopSize = Size(1280, 800);
        tester.view.physicalSize = desktopSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestHost(
            size: desktopSize,
            child: const FirstPersonCockpitViewportWidget(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Zmiana biegów
        await tester.tap(find.text('Bieg + (R)'));
        await tester.pump(const Duration(milliseconds: 120));
        await tester.tap(find.text('Bieg - (L)'));
        await tester.pump(const Duration(milliseconds: 120));

        // Zmiana chwytu kierownicy
        await tester.tap(find.text('Dolny chwyt (Drops)'));
        await tester.pump(const Duration(milliseconds: 150));
        await tester.tap(find.text('Pozycja Aero (Tuck)'));
        await tester.pump(const Duration(milliseconds: 150));

        // Przełączenie modelu licznika Garmin -> Wahoo
        expect(find.text('Garmin'), findsOneWidget);
        await tester.ensureVisible(find.text('Garmin'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('Garmin'));
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('Wahoo'), findsOneWidget);

        // Przełączenie odstępu peletonu 30 cm -> 1.8 m
        expect(find.text('30 cm Peleton'), findsOneWidget);
        await tester.ensureVisible(find.text('30 cm Peleton'));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.text('30 cm Peleton'));
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('1.8 m Odstęp'), findsOneWidget);

        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets(
      'renderuje wariant bez kontrolek interaktywnych oraz w układzie Wahoo',
      (WidgetTester tester) async {
        const Size tabletSize = Size(1024, 768);
        tester.view.physicalSize = tabletSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _buildTestHost(
            size: tabletSize,
            child: const FirstPersonCockpitViewportWidget(
              initialComputerModel: BikeComputerModel.wahooElemnt,
              initialGripPosture: CockpitGripPosture.drops,
              showInteractiveControls: false,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('Bieg - (L)'), findsNothing);
        expect(find.text('PRO CYCLIST COCKPIT 3D'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  });

  group('CollectibleProRiderHoloCard', () {
    const List<Size> responsiveSizes = <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ];

    for (final Size viewportSize in responsiveSizes) {
      testWidgets(
        'renderuje karty kolekcjonerskie wszystkich rang bez przepełnień na ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          tester.view.physicalSize = viewportSize;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          final CollectibleProRiderCardData goldCard = _createSampleCardData(
            riderId: 'rider_gold',
            fullName: 'Tadej Pogačar',
            ovr: 96,
            specialJersey: SpecialJerseyDesignation.rainbowJersey,
            grandTourWins: const <GrandTourWinBadge>[
              GrandTourWinBadge(
                tour: GrandTourType.tourDeFrance,
                years: <int>[2020, 2021, 2024],
              ),
              GrandTourWinBadge(
                tour: GrandTourType.giroDItalia,
                years: <int>[2024],
              ),
            ],
          );

          final CollectibleProRiderCardData silverCard = _createSampleCardData(
            riderId: 'rider_silver',
            fullName: 'Filippo Ganna',
            ovr: 87,
          );

          final CollectibleProRiderCardData carbonCard = _createSampleCardData(
            riderId: 'rider_carbon',
            fullName: 'Michał Kwiatkowski',
            ovr: 79,
          );

          await tester.pumpWidget(
            _buildTestHost(
              size: viewportSize,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: <Widget>[
                    CollectibleProRiderHoloCard(
                      data: goldCard,
                      isSelected: true,
                      onTap: () {},
                    ),
                    CollectibleProRiderHoloCard(
                      data: silverCard,
                      onTap: () {},
                    ),
                    CollectibleProRiderHoloCard(
                      data: carbonCard,
                      enabled: false,
                    ),
                  ],
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
          expect(find.byType(CollectibleProRiderHoloCard), findsNWidgets(3));
          expect(find.text('TADEJ POGAČAR'), findsOneWidget);
          expect(find.text('FILIPPO GANNA'), findsOneWidget);
          expect(find.text('MICHAŁ KWIATKOWSKI'), findsOneWidget);
          expect(find.text('96'), findsOneWidget);
          expect(find.text('87'), findsOneWidget);
          expect(find.text('79'), findsOneWidget);
          expect(find.text('MON'), findsNWidgets(3));
          expect(find.text('REC'), findsNWidgets(3));

          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }

    testWidgets(
      'obsługuje strumień pochylenia żyroskopu, hover, fokus klawiatury i kliknięcie',
      (WidgetTester tester) async {
        const Size desktopSize = Size(1024, 768);
        tester.view.physicalSize = desktopSize;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final StreamController<HoloTiltSample> tiltController =
            StreamController<HoloTiltSample>.broadcast();
        int tapCount = 0;

        final CollectibleProRiderCardData cardData = _createSampleCardData(
          riderId: 'rider_tilt',
          fullName: 'Jonas Vingegaard',
          ovr: 94,
          grandTourWins: const <GrandTourWinBadge>[
            GrandTourWinBadge(
              tour: GrandTourType.tourDeFrance,
              years: <int>[2022, 2023],
            ),
          ],
        );

        await tester.pumpWidget(
          _buildTestHost(
            size: desktopSize,
            child: Center(
              child: CollectibleProRiderHoloCard(
                data: cardData,
                tiltStream: tiltController.stream,
                onTap: () => tapCount++,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Emisja pochylenia ze strumienia (żyroskop)
        tiltController.add(const HoloTiltSample(0.65, -0.45));
        await tester.pump(const Duration(milliseconds: 200));

        // Symulacja hover myszą
        final TestGesture gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(
          tester.getCenter(find.byType(CollectibleProRiderHoloCard)),
        );
        await tester.pump(const Duration(milliseconds: 200));

        // Kliknięcie karty
        await tester.tap(find.byType(CollectibleProRiderHoloCard));
        await tester.pump(const Duration(milliseconds: 200));
        expect(tapCount, 1);

        // Aktywacja klawiaturą po uzyskaniu fokusu
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump(const Duration(milliseconds: 150));

        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(() async {
          await tiltController.close();
        });
      },
    );
  });
}
