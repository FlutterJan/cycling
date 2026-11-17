// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/bike_sponsor_custom_prototype_lab.dart';
import 'package:pro_peloton_manager/ui/widgets/skunkworks_prototype_blueprint_painter.dart';

SkunkworksPrototypeSpec _buildTestPrototype({
  SkunkworksPrototypeCategory category = SkunkworksPrototypeCategory.aeroTtFrame,
  SkunkworksSecrecyLevel secrecyLevel = SkunkworksSecrecyLevel.topSecret,
  double failureRiskPercent = 8.5,
  double uciMargin = 6.0,
}) {
  return SkunkworksPrototypeSpec(
    id: 'skunk_test_01',
    codename: 'PROJECT VALKYRIE X9',
    manufacturerId: 'mfg_pinarello',
    manufacturerName: 'Pinarello Skunkworks',
    category: category,
    targetRaceTier: SkunkworksTargetRaceTier.grandTour,
    targetRaceName: 'Tour de France',
    phase: SkunkworksPrototypePhase.windTunnelTesting,
    secrecyLevel: secrecyLevel,
    cdaDeltaPercent: -3.4,
    weightDeltaGrams: -190,
    drivetrainWattSavings: 4.8,
    vibrationDampingBonusPercent: 6.2,
    stiffnessToWeightRatio: 118.4,
    failureRiskPercent: failureRiskPercent,
    uciComplianceMarginPercent: uciMargin,
    developmentProgress: 0.68,
    windTunnelHoursLogged: 24,
    windTunnelHoursRequired: 40,
    budgetAllocatedEur: 185000,
    totalCostEur: 240000,
    assignedLeadRiderId: 'rider_1',
    assignedLeadRiderName: 'Jonas Vingegaard',
    isPrototypeActiveForRace: false,
    cadBlueprintSeed: 4242,
    engineeringNotes: 'Kammtail 6.4:1 profilu rury dolnej, wlokno T1100 1K.',
  );
}

void main() {
  group('SkunkworksBlueprintGeometryCalculator', () {
    test('wylicza deterministyczna geometrie dla roznych kategorii', () {
      final aeroProto = _buildTestPrototype(
        category: SkunkworksPrototypeCategory.aeroTtFrame,
      );
      final climbProto = _buildTestPrototype(
        category: SkunkworksPrototypeCategory.ultralightClimbingChassis,
      );

      final aeroGeo = SkunkworksBlueprintGeometryCalculator.computeGeometry(aeroProto);
      final climbGeo = SkunkworksBlueprintGeometryCalculator.computeGeometry(climbProto);

      expect(aeroGeo.wheelRimDepthMm, greaterThan(climbGeo.wheelRimDepthMm));
      expect(aeroGeo.tubeChordRatio, greaterThan(climbGeo.tubeChordRatio));
      expect(aeroGeo.seatTubeAngleDeg, greaterThan(climbGeo.seatTubeAngleDeg));
      expect(aeroGeo.peakStressMpa, inInclusiveRange(280.0, 680.0));
      expect(aeroGeo.cfdDragReductionN, greaterThan(0.4));
    });

    test('buduje 5 unikalnych pinow CAD z prawidlowymi wspolrzednymi', () {
      final proto = _buildTestPrototype();
      final geo = SkunkworksBlueprintGeometryCalculator.computeGeometry(proto);
      final pins = SkunkworksBlueprintGeometryCalculator.buildCalloutPins(proto, geo);

      expect(pins, hasLength(5));
      for (final pin in pins) {
        expect(pin.normalizedPosition.dx, inInclusiveRange(0.0, 1.0));
        expect(pin.normalizedPosition.dy, inInclusiveRange(0.0, 1.0));
        expect(pin.title, isNotEmpty);
        expect(pin.metricValue, isNotEmpty);
      }
    });
  });

  group('SkunkworksPrototypeBlueprintWidget', () {
    testWidgets('renderuje bez bledow i obsluguje zmiane trybu, motywu i warstw', (
      WidgetTester tester,
    ) async {
      final proto = _buildTestPrototype();
      BlueprintCalloutPin? selectedFromCallback;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SkunkworksPrototypeBlueprintWidget(
                prototype: proto,
                onCalloutSelected: (pin) => selectedFromCallback = pin,
                onExportBlueprint: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('PROJECT VALKYRIE X9'), findsOneWidget);
      expect(find.text('TELEMETRIA INŻYNIERYJNA'), findsOneWidget);

      // Przelaczenie na Przekroj Aero
      await tester.tap(find.text('Przekrój Aero'));
      await tester.pump(const Duration(milliseconds: 250));

      // Przelaczenie na Naped & Mufa
      await tester.tap(find.text('Napęd & Mufa'));
      await tester.pump(const Duration(milliseconds: 250));

      // Przelaczenie motywu kolorystycznego
      await tester.tap(find.text('Skunkworks Gold'));
      await tester.pump(const Duration(milliseconds: 250));

      // Klikniecie pina #2
      await tester.ensureVisible(find.text('#2'));
      await tester.tap(find.text('#2'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(selectedFromCallback?.id, 'bb_stiffness');

      // Wlaczenie warstwy Naprezenia FEA
      await tester.ensureVisible(find.text('Naprężenia FEA'));
      await tester.tap(find.text('Naprężenia FEA'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(tester.takeException(), isNull);
    });

    testWidgets('tryb disabled blokuje interakcje i wyswietla etykiete podgladu', (
      WidgetTester tester,
    ) async {
      final proto = _buildTestPrototype();
      BlueprintCalloutPin? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SkunkworksPrototypeBlueprintWidget(
                prototype: proto,
                enabled: false,
                onCalloutSelected: (pin) => selected = pin,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TRYB PODGLĄDU'), findsOneWidget);

      await tester.ensureVisible(find.text('#1'));
      await tester.tap(find.text('#1'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    });

    for (final viewportSize in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'responsywnosc bez RenderFlex overflow przy ${viewportSize.width.toInt()}x${viewportSize.height.toInt()}',
        (WidgetTester tester) async {
          await tester.binding.setSurfaceSize(viewportSize);
          addTearDown(() => tester.binding.setSurfaceSize(null));

          final proto = _buildTestPrototype(
            category: SkunkworksPrototypeCategory.cobbleSuspensionCockpit,
            secrecyLevel: SkunkworksSecrecyLevel.restricted,
          );

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: SkunkworksPrototypeBlueprintWidget(
                    prototype: proto,
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
