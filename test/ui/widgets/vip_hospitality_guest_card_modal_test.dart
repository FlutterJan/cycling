import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/services/career/team_sponsor_hospitality_vip_events.dart';
import 'package:pro_peloton_manager/ui/widgets/vip_hospitality_guest_card_modal.dart';

Widget _wrapModal({
  required VipHospitalityGuestCardData data,
  ValueChanged<VipHospitalityGuestCardResult>? onConfirm,
  VoidCallback? onCancel,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    home: Scaffold(
      body: Center(
        child: VipHospitalityGuestCardModal(
          data: data,
          onConfirmInvitation: onConfirm,
          onCancel: onCancel,
        ),
      ),
    ),
  );
}

void main() {
  group('VipHospitalityBonusCalculator & Data', () {
    test('serializes and deserializes VipHospitalityGuestCardData JSON', () {
      final original = VipHospitalityGuestCardData.sample();
      final decoded =
          VipHospitalityGuestCardData.fromJson(original.toJson());

      expect(decoded.sponsorId, original.sponsorId);
      expect(decoded.sponsorName, original.sponsorName);
      expect(decoded.venue, original.venue);
      expect(decoded.guests.length, original.guests.length);
      expect(decoded.availablePackages.length, 3);
      expect(decoded.initialSelectedPackages, original.initialSelectedPackages);
    });

    test('computes relationship bonus with preference match and empty edge', () {
      final data = VipHospitalityGuestCardData.sample();

      final emptyBonus = VipHospitalityBonusCalculator.calculateBonus(
        currentRelationshipScore: 64.0,
        venue: data.venue,
        selectedGuests: const [],
        selectedPackages: const [],
      );
      expect(emptyBonus.totalRelationshipBonus, 0.0);
      expect(emptyBonus.projectedRelationshipScore, 64.0);

      final singleMatch = VipHospitalityBonusCalculator.calculateBonus(
        currentRelationshipScore: 64.0,
        venue: data.venue,
        selectedGuests: [data.guests.first],
        selectedPackages: const [
          VipHospitalityExperiencePackage.secondTeamCarConvoy,
        ],
      );
      expect(singleMatch.matchedGuestPreferencesCount, 1);
      expect(singleMatch.preferenceMatchBonus, 2.5);
      expect(singleMatch.totalRelationshipBonus, greaterThan(10.0));
      expect(singleMatch.projectedRelationshipScore, greaterThan(74.0));
    });
  });

  group('VipHospitalityGuestCardModal Widget Tests', () {
    testWidgets('renders 3 core attractions and updates bonus on selection',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      VipHospitalityGuestCardResult? confirmedResult;
      final data = VipHospitalityGuestCardData.sample();

      await tester.pumpWidget(
        _wrapModal(
          data: data,
          onConfirm: (res) => confirmedResult = res,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Przejazd w wozie dyrektora sportowego'),
        findsOneWidget,
      );
      expect(
        find.text('Spotkanie z liderem w autobusie po etapie'),
        findsOneWidget,
      );
      expect(
        find.text('Pamiątkowa koszulka z autografami'),
        findsOneWidget,
      );

      await tester.tap(
        find.text('Spotkanie z liderem w autobusie po etapie'),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Pamiątkowa koszulka z autografami'));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Wyślij Zaproszenie VIP'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(confirmedResult, isNotNull);
      expect(confirmedResult!.selectedPackages.length, 3);
      expect(
        confirmedResult!.bonusBreakdown.totalRelationshipBonus,
        greaterThan(20.0),
      );
    });

    testWidgets('blocks confirmation when over budget or readOnly or empty',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 860));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      VipHospitalityGuestCardResult? confirmedResult;
      final overBudgetData = VipHospitalityGuestCardData.sample().copyWith(
        availableTeamBudgetEur: 5000,
      );

      await tester.pumpWidget(
        _wrapModal(
          data: overBudgetData,
          onConfirm: (res) => confirmedResult = res,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Koszt przekracza dostępny budżet zespołu.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Wyślij Zaproszenie VIP'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(confirmedResult, isNull);

      final readOnlyEmptyData =
          VipHospitalityGuestCardData.sample(isReadOnly: true).copyWith(
        guests: const [],
      );
      await tester.pumpWidget(
        _wrapModal(
          data: readOnlyEmptyData,
          onConfirm: (res) => confirmedResult = res,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('TYLKO PODGLĄD'), findsOneWidget);
      expect(
        find.text('Brak dostępnych przedstawicieli sponsora do zaproszenia.'),
        findsOneWidget,
      );
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders cleanly without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          _wrapModal(data: VipHospitalityGuestCardData.sample()),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.byType(VipHospitalityGuestCardModal), findsOneWidget);
      });
    }
  });
}
