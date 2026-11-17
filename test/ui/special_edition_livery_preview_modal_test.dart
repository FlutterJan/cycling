// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/services/career/sponsor_custom_color_rebrand_events.dart';
import 'package:pro_peloton_manager/ui/widgets/special_edition_livery_preview_modal.dart';

SpecialEditionLiveryProposal _buildSampleProposal({
  String primaryHex = '#1E3A8A',
  SpecialLiveryThemeType theme = SpecialLiveryThemeType.sponsorAnniversary,
}) {
  return SpecialEditionLiveryProposal(
    id: 'livery_tdf_2026_jubilee',
    grandTour: GrandTourLiveryEvent.tourDeFrance,
    theme: theme,
    bikeFinish: BikePaintFinish.metallicFlake,
    palette: LiveryColorPalette(
      primaryJerseyHex: primaryHex,
      secondaryJerseyHex: '#0F172A',
      accentJerseyHex: '#D4AF37',
      bikeFrameHex: '#1E293B',
      wheelDecalHex: '#D4AF37',
      helmetHex: '#F3F4F6',
    ),
    editionTitle: 'Édition Or & Azur — 25 Ans',
    sponsorName: 'Aetheris Energy',
    bikeManufacturerName: 'Veloce',
    bikeModelName: 'AeroBlade SL8',
    sponsorPitch:
        'Na 25-lecie partnerstwa przygotowaliśmy limitowany strój oraz ramę w odcieniu głębokiego kobaltu i złota.',
    merchandiseRevenueBonusEur: 185000,
    productionCostEur: 45000,
    mediaExposureMultiplier: 1.45,
    sponsorSatisfactionDelta: 14,
    teamMoraleBonus: 6,
    uciClashResolved: true,
  );
}

Future<void> _pumpModalAtSize(
  WidgetTester tester, {
  required Size size,
  required SpecialEditionLiveryProposal proposal,
  bool isReadOnly = false,
  ValueChanged<SpecialEditionLiveryModalOutcome>? onOutcome,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SpecialEditionLiveryPreviewModal(
          proposal: proposal,
          teamName: 'Bora-Veloce Pro',
          isReadOnly: isReadOnly,
          onOutcome: onOutcome,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('SpecialEditionLiveryPreviewCalculator & Outcome JSON', () {
    test('detects UCI clash when primary jersey matches Maillot Jaune', () {
      const yellowPalette = LiveryColorPalette(
        primaryJerseyHex: '#FACC15',
        secondaryJerseyHex: '#181B22',
        accentJerseyHex: '#D4AF37',
        bikeFrameHex: '#181B22',
        wheelDecalHex: '#D4AF37',
        helmetHex: '#F3F4F6',
      );
      const navyPalette = LiveryColorPalette(
        primaryJerseyHex: '#1E3A8A',
        secondaryJerseyHex: '#0F172A',
        accentJerseyHex: '#D4AF37',
        bikeFrameHex: '#1E293B',
        wheelDecalHex: '#D4AF37',
        helmetHex: '#F3F4F6',
      );

      expect(
        SpecialEditionLiveryPreviewCalculator.isUciCompliant(
          palette: yellowPalette,
          grandTour: GrandTourLiveryEvent.tourDeFrance,
        ),
        isFalse,
      );
      expect(
        SpecialEditionLiveryPreviewCalculator.isUciCompliant(
          palette: navyPalette,
          grandTour: GrandTourLiveryEvent.tourDeFrance,
        ),
        isTrue,
      );
    });

    test('computes net profit with and without merch drop', () {
      final proposal = _buildSampleProposal();
      expect(
        SpecialEditionLiveryPreviewCalculator.computeNetProfitEur(
          proposal: proposal,
          includeMerchDrop: true,
        ),
        140000,
      );
      expect(
        SpecialEditionLiveryPreviewCalculator.computeNetProfitEur(
          proposal: proposal,
          includeMerchDrop: false,
        ),
        58500,
      );
    });

    test('SpecialEditionLiveryModalOutcome round-trips JSON cleanly', () {
      final proposal = _buildSampleProposal();
      final outcome = SpecialEditionLiveryModalOutcome(
        action: SpecialEditionLiveryModalAction.customizedAndApproved,
        proposalId: proposal.id,
        selectedPalette: proposal.palette,
        selectedBikeFinish: BikePaintFinish.satinRaw,
        includeMerchDrop: false,
        uciColorDistance: 0.62,
        decidedAt: DateTime(2026, 7, 2, 14, 30),
      );

      final parsed =
          SpecialEditionLiveryModalOutcome.fromJson(outcome.toJson());
      expect(parsed.action, SpecialEditionLiveryModalAction.customizedAndApproved);
      expect(parsed.proposalId, proposal.id);
      expect(parsed.selectedPalette, proposal.palette);
      expect(parsed.selectedBikeFinish, BikePaintFinish.satinRaw);
      expect(parsed.includeMerchDrop, isFalse);
      expect(parsed.uciColorDistance, closeTo(0.62, 1e-6));
    });
  });

  group('SpecialEditionLiveryPreviewModal responsive & interactive', () {
    for (final size in const <Size>[
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
        'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          await _pumpModalAtSize(
            tester,
            size: size,
            proposal: _buildSampleProposal(),
          );

          expect(find.text('Édition Or & Azur — 25 Ans'), findsOneWidget);
          expect(find.text('Zatwierdź malowanie'), findsOneWidget);
          expect(find.text('Odrzuć propozycję'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('supports finish customization and emits customizedAndApproved',
        (tester) async {
      SpecialEditionLiveryModalOutcome? captured;
      await _pumpModalAtSize(
        tester,
        size: const Size(1280, 820),
        proposal: _buildSampleProposal(),
        onOutcome: (outcome) => captured = outcome,
      );

      final finishChip = find.text('Satyna Raw Carbon (-35g)');
      await tester.ensureVisible(finishChip);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(finishChip);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('-35 g'), findsOneWidget);
      expect(find.text('Zatwierdź własną edycję'), findsOneWidget);

      await tester.tap(find.text('Zatwierdź własną edycję'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(captured, isNotNull);
      expect(
        captured!.action,
        SpecialEditionLiveryModalAction.customizedAndApproved,
      );
      expect(captured!.selectedBikeFinish, BikePaintFinish.satinRaw);
    });

    testWidgets('disables editing and approval when isReadOnly is true',
        (tester) async {
      SpecialEditionLiveryModalOutcome? captured;
      await _pumpModalAtSize(
        tester,
        size: const Size(1280, 820),
        proposal: _buildSampleProposal(),
        isReadOnly: true,
        onOutcome: (outcome) => captured = outcome,
      );

      expect(find.text('TYLKO PODGLĄD'), findsOneWidget);

      await tester.tap(find.text('Zatwierdź malowanie'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(captured, isNull);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(captured?.action, SpecialEditionLiveryModalAction.dismissed);
    });
  });
}
