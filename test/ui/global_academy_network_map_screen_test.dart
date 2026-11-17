import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/global_satellite_training_centers_service.dart';
import 'package:pro_peloton_manager/ui/screens/global_academy_network_map_screen.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    required Size size,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: GlobalAcademyNetworkMapScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('GlobalAcademyNetworkMapScreen', () {
    for (final entry in <String, Size>{
      '390x844': const Size(390, 844),
      '1024x768': const Size(1024, 768),
      '1600x900': const Size(1600, 900),
    }.entries) {
      testWidgets('renderuje bez przepełnienia w rozdzielczości ${entry.key}',
          (tester) async {
        await pumpScreen(tester, size: entry.value);
        expect(find.text('Globalna Sieć Akademii Treningowych'), findsOneWidget);
        expect(find.text('Mapa Satelitarna Sieci Akademii'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('obsługuje wybór regionu, zakładki oraz akcje na sieci akademii',
        (tester) async {
      await pumpScreen(tester, size: const Size(1600, 900));

      // Domyślnie wybrana Sierra Nevada
      expect(find.text('Sierra Nevada — CAR Granada'), findsOneWidget);

      // Przełącz region na Kolumbię
      await tester.tap(find.text('Kolumbia').first);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Kolumbia — Boyacá / Andy'), findsOneWidget);

      // Zbuduj akademię w Kolumbii
      final buildBtn = find.textContaining('Zbuduj');
      expect(buildBtn, findsOneWidget);
      await tester.tap(buildBtn);
      await tester.pump(const Duration(milliseconds: 250));

      // Przełącz zakładkę na Talenty U19/U23 i wyszukaj talent
      await tester.tap(find.text('Talenty U19/U23'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('Skautuj U19/U23'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Awansuj do Kadry Pro'), findsAtLeastNWidgets(1));

      // Przełącz na Obozy Pro i wyślij kolarza na obóz
      await tester.tap(find.text('Obozy Pro'));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.textContaining('Rozpocznij Zgrupowanie'));
      await tester.pump(const Duration(milliseconds: 250));

      // Symuluj +7 dni
      await tester.tap(find.text('+7 dni'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Zasymulowano 7 dni'), findsOneWidget);

      // Przełącz na Logistykę Sieci
      await tester.tap(find.text('Logistyka Sieci'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.textContaining('Prestiż Sieci'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('projekcja geograficzna mapy mieści wszystkie regiony w granicach canvasu',
        () {
      for (final region in SatelliteAcademyRegionId.values) {
        final offset = WorldAcademyNetworkMapPainter.projectGeo(
          latitude: region.latitude,
          longitude: region.longitude,
          width: 800,
          height: 450,
        );
        expect(offset.dx, inInclusiveRange(0.0, 800.0));
        expect(offset.dy, inInclusiveRange(0.0, 450.0));
      }
    });
  });
}
