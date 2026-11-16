import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/ui/widgets/otl_time_cut_warning_banner_hud.dart';

void main() {
  group('OtlTimeCutWarningData', () {
    test('calculates severity thresholds and recovery projections accurately',
        () {
      final safe = OtlTimeCutWarningData.sampleSafe();
      expect(safe.severity, OtlWarningSeverity.safe);
      expect(safe.shouldDisplayAlert, isFalse);

      final warning = OtlTimeCutWarningData.sampleWarning(
        marginToOtlSeconds: 95.0,
      );
      expect(warning.severity, OtlWarningSeverity.warning);
      expect(warning.shouldDisplayAlert, isTrue);
      expect(warning.selectedDomestiqueIds, ['dom-1', 'dom-2']);
      expect(warning.estimatedRecoverySeconds, 100.0);
      expect(warning.projectedMarginAfterHelpSeconds, 195.0);

      final critical = warning.copyWith(marginToOtlSeconds: 32.0);
      expect(critical.severity, OtlWarningSeverity.critical);
      expect(critical.shouldDisplayAlert, isTrue);

      final negative = warning.copyWith(marginToOtlSeconds: -18.0);
      expect(negative.severity, OtlWarningSeverity.critical);

      final disabled = warning.copyWith(isEnabled: false);
      expect(disabled.severity, OtlWarningSeverity.disabled);
      expect(disabled.shouldDisplayAlert, isFalse);
    });

    test('round-trips through JSON serialization', () {
      final original = OtlTimeCutWarningData.sampleWarning(
        marginToOtlSeconds: 68.0,
        orderStatus: OtlDropBackOrderStatus.dispatched,
      );
      final json = original.toJson();
      final decoded = OtlTimeCutWarningData.fromJson(json);

      expect(decoded, equals(original));
      expect(decoded.orderStatus, OtlDropBackOrderStatus.dispatched);
      expect(decoded.availableDomestiques.length, 2);
    });
  });

  group('OtlTimeCutWarningBannerHud widget', () {
    testWidgets('hides when margin >= 120s and showWhenSafe is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtlTimeCutWarningBannerHud(
              data: OtlTimeCutWarningData.sampleSafe(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OTL SAFE'), findsNothing);
      expect(find.text('OTL WARNING'), findsNothing);
    });

    testWidgets(
        'displays pulsing warning and dispatches/cancels drop-back order',
        (tester) async {
      List<String>? dispatchedIds;
      String? toggledId;
      var cancelled = false;
      var focused = false;

      var data = OtlTimeCutWarningData.sampleWarning(
        marginToOtlSeconds: 74.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: SizedBox(
                    width: 820,
                    child: OtlTimeCutWarningBannerHud(
                      data: data,
                      onFocusRiderIn3d: () => focused = true,
                      onToggleDomestiqueSelection: (id) {
                        toggledId = id;
                        setState(() {
                          data = data.copyWith(
                            availableDomestiques: data.availableDomestiques
                                .map(
                                  (d) => d.riderId == id
                                      ? d.copyWith(isSelected: !d.isSelected)
                                      : d,
                                )
                                .toList(),
                          );
                        });
                      },
                      onDispatchDropBackOrder: (ids) {
                        dispatchedIds = ids;
                        setState(() {
                          data = data.copyWith(
                            orderStatus: OtlDropBackOrderStatus.dispatched,
                            availableDomestiques: data.availableDomestiques
                                .map(
                                  (d) => ids.contains(d.riderId)
                                      ? d.copyWith(isDispatched: true)
                                      : d,
                                )
                                .toList(),
                          );
                        });
                      },
                      onCancelDropBackOrder: () {
                        cancelled = true;
                        setState(() {
                          data = data.copyWith(
                            orderStatus: OtlDropBackOrderStatus.available,
                            availableDomestiques: data.availableDomestiques
                                .map((d) => d.copyWith(isDispatched: false))
                                .toList(),
                          );
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('OTL WARNING'), findsOneWidget);
      expect(find.text('+01:14'), findsOneWidget);
      expect(find.text('T. Zieliński'), findsOneWidget);
      expect(find.text('P. Nowak'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.videocam_rounded));
      await tester.pump(const Duration(milliseconds: 200));
      expect(focused, isTrue);

      await tester.tap(find.text('P. Nowak'));
      await tester.pump(const Duration(milliseconds: 250));
      expect(toggledId, 'dom-2');

      await tester.tap(find.textContaining('Cofnij kolegów (1)'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(dispatchedIds, ['dom-1']);
      expect(find.text('Koledzy w drodze do Grupetto'), findsOneWidget);
      expect(find.text('Odwołaj rozkaz'), findsOneWidget);

      await tester.tap(find.text('Odwołaj rozkaz'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(cancelled, isTrue);
      expect(find.textContaining('Cofnij kolegów (1)'), findsOneWidget);
    });

    testWidgets('handles empty domestiques and disabled state gracefully',
        (tester) async {
      final noHelpers = OtlTimeCutWarningData.sampleWarning(
        marginToOtlSeconds: 28.0,
        orderStatus: OtlDropBackOrderStatus.noDomestiquesAvailable,
      ).copyWith(availableDomestiques: const []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtlTimeCutWarningBannerHud(
              data: noHelpers,
              enablePulseAnimation: false,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('HORS DÉLAIS RISK'), findsOneWidget);
      expect(find.text('Brak pomocników do cofnięcia'), findsOneWidget);
    });

    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: OtlTimeCutWarningBannerHud(
                  data: OtlTimeCutWarningData.sampleWarning(
                    marginToOtlSeconds: 38.0,
                  ),
                  onDispatchDropBackOrder: (_) {},
                  onToggleDomestiqueSelection: (_) {},
                  onFocusRiderIn3d: () {},
                  onDismiss: () {},
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
        expect(find.text('HORS DÉLAIS RISK'), findsOneWidget);
        expect(find.text('K. Majewski (PLM)'), findsOneWidget);
      });
    }
  });
}
