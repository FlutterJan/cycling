import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/services/career/overtraining_and_burnout_diagnostics.dart';

Rider _buildTestRider({
  String id = 'rider_1',
  String firstName = 'Michał',
  String lastName = 'Kwiatkowski',
  int ftpWatts = 400,
  int maxHr = 195,
  double ctl = 80.0,
  double atl = 90.0,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: 'POL',
    birthDate: DateTime(1995, 6, 2),
    potential: 90,
    specialization: RiderSpecialization.gcClimber,
    physiology: RiderPhysiology(
      heightCm: 176.0,
      weightKg: 68.0,
      bodyFatPercentage: 7.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: 22000,
      vo2Max: 84.0,
      maxHr: maxHr,
      restingHr: 42,
      lactateThresholdHr: 175,
      recoveryRate: 0.85,
      glycogenCapacityGrams: 520.0,
      form: ctl,
      fatigue: atl,
    ),
    powerProfile: const RiderPowerProfile(
      watts5s: 1280,
      watts15s: 1050,
      watts30s: 840,
      watts1m: 660,
      watts3m: 510,
      watts5m: 470,
      watts20m: 420,
      watts60m: 400,
    ),
    skills: const RiderSkills(
      cobbles: 78,
      descending: 84,
      bikeHandling: 86,
      aeroPositioning: 82,
      draftingEfficiency: 80,
      raceIq: 88,
      rainResistance: 79,
      heatTolerance: 76,
      timeTrialPositioning: 83,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 1,
      skinToneHex: '#F1C27D',
      hairStyleIndex: 2,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#00E5FF',
      helmetModelId: 'vent_pro',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.65,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_pl',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 65000,
      signingBonusEur: 0,
      winBonusEur: 15000,
      releaseClauseEur: 1500000,
      contractEndYear: 2028,
      morale: 0.85,
      leaderLoyalty: 0.9,
      requiredRacesIds: <String>[],
    ),
    health: RiderHealth(
      acuteTrainingLoad: atl,
      chronicTrainingLoad: ctl,
    ),
    careerPointsUci: 1450,
  );
}

void main() {
  const diagnostics = OvertrainingAndBurnoutDiagnostics();

  group('OvertrainingAndBurnoutDiagnostics - model i progi', () {
    test('kolarz w bezpiecznym zakresie obciążenia otrzymuje status optimal', () {
      final rider = _buildTestRider(ctl: 85.0, atl: 90.0);
      final report = diagnostics.evaluateRider(
        rider: rider,
        consecutiveDaysBelowTsbLimit: 0,
        seasonRaceDays: 42,
      );

      expect(report.severity, OvertrainingSeverity.optimal);
      expect(report.triggerReason, OvertrainingTriggerReason.none);
      expect(report.parasympatheticSyndromeTriggered, isFalse);
      expect(report.maxHrSuppressionBpm, 0);
      expect(report.ftpDropPercentage, 0.0);
      expect(report.effectiveMaxHrBpm, 195);
      expect(report.effectiveFtpWatts, 400);
      expect(report.recommendedRestDays, 0);
    });

    test('granica 14 dni z TSB < -35 i 85 dni wyścigowych nie wywołuje jeszcze OTS', () {
      final rider = _buildTestRider(ctl: 75.0, atl: 115.0); // TSB = -40
      final report = diagnostics.evaluateRider(
        rider: rider,
        consecutiveDaysBelowTsbLimit: 14,
        seasonRaceDays: 85,
      );

      expect(report.parasympatheticSyndromeTriggered, isFalse);
      expect(report.severity, OvertrainingSeverity.nonFunctionalOverreaching);
      expect(report.maxHrSuppressionBpm, 0);
      expect(report.ftpDropPercentage, 0.0);
    });

    test('TSB < -35 przez >14 dni (15 dni) wywołuje OTS: -15 BPM MaxHR i -8% FTP', () {
      final rider = _buildTestRider(
        ftpWatts: 400,
        maxHr: 195,
        ctl: 70.0,
        atl: 110.0, // TSB = -40
      );

      final report = diagnostics.evaluateRider(
        rider: rider,
        consecutiveDaysBelowTsbLimit: 15,
        seasonRaceDays: 50,
      );

      expect(report.parasympatheticSyndromeTriggered, isTrue);
      expect(
        report.severity,
        OvertrainingSeverity.parasympatheticOvertraining,
      );
      expect(
        report.triggerReason,
        OvertrainingTriggerReason.prolongedDeepNegativeTsb,
      );
      expect(report.maxHrSuppressionBpm, 15);
      expect(report.effectiveMaxHrBpm, 180); // 195 - 15
      expect(report.ftpDropPercentage, 0.08);
      expect(report.effectiveFtpWatts, 368); // 400 * 0.92
      expect(report.recommendedRestDays, greaterThanOrEqualTo(10));

      final penalizedRider =
          diagnostics.applyParasympatheticPenaltyToRider(rider, report);
      expect(penalizedRider.physiology.maxHr, 180);
      expect(penalizedRider.physiology.ftpWatts, 368);
    });

    test('ponad 85 dni wyścigowych (86 dni) wywołuje wypalenie sezonowe i OTS', () {
      final rider = _buildTestRider(
        ftpWatts: 375,
        maxHr: 190,
        ctl: 80.0,
        atl: 85.0, // TSB = -5
      );

      final report = diagnostics.evaluateRider(
        rider: rider,
        consecutiveDaysBelowTsbLimit: 0,
        seasonRaceDays: 86,
      );

      expect(report.parasympatheticSyndromeTriggered, isTrue);
      expect(report.severity, OvertrainingSeverity.seasonalBurnout);
      expect(
        report.triggerReason,
        OvertrainingTriggerReason.excessiveSeasonRaceDays,
      );
      expect(report.maxHrSuppressionBpm, 15);
      expect(report.effectiveMaxHrBpm, 175); // 190 - 15
      expect(report.ftpDropPercentage, 0.08);
      expect(report.effectiveFtpWatts, 345); // 375 * 0.92 = 345
      expect(
        report.recommendedInterventions,
        contains(BurnoutRecoveryIntervention.seasonEndShutdown),
      );
    });

    test('kumulacja obu warunków daje dualLoadAndRaceBurnout', () {
      final rider = _buildTestRider(ctl: 60.0, atl: 105.0);
      final report = diagnostics.evaluateRider(
        rider: rider,
        consecutiveDaysBelowTsbLimit: 18,
        seasonRaceDays: 92,
      );

      expect(report.parasympatheticSyndromeTriggered, isTrue);
      expect(
        report.triggerReason,
        OvertrainingTriggerReason.dualLoadAndRaceBurnout,
      );
      expect(report.burnoutRiskScore, greaterThanOrEqualTo(85.0));
    });

    test('recordDailyTelemetry kumuluje dni TSB < -35 i wygasza zespół po regeneracji', () {
      var tracker = const RiderBurnoutTrackerState(riderId: 'rider_1');

      for (int i = 0; i < 15; i++) {
        tracker = diagnostics.recordDailyTelemetry(
          state: tracker,
          tsb: -38.0,
          racedToday: false,
          date: DateTime(2026, 7, 1 + i),
        );
      }

      expect(tracker.consecutiveDeepNegativeTsbDays, 15);
      expect(tracker.parasympatheticSyndromeActive, isTrue);

      // Najpierw reset serii głębokiego TSB (TSB >= -20) i 10 dni pełnej regeneracji (TSB >= 0)
      for (int i = 0; i < 10; i++) {
        tracker = diagnostics.recordDailyTelemetry(
          state: tracker,
          tsb: 5.0,
          racedToday: false,
          date: DateTime(2026, 7, 16 + i),
        );
      }

      expect(tracker.consecutiveDeepNegativeTsbDays, 0);
      expect(tracker.parasympatheticSyndromeActive, isFalse);
    });

    test('auditSquad sortuje raporty od najwyższego ryzyka i zlicza kategorie', () {
      final riderHealthy = _buildTestRider(id: 'r_ok', firstName: 'Jan');
      final riderWarn = _buildTestRider(
        id: 'r_warn',
        firstName: 'Piotr',
        ctl: 75,
        atl: 112,
      );
      final riderOts = _buildTestRider(
        id: 'r_ots',
        firstName: 'Adam',
        ctl: 65,
        atl: 115,
      );

      final audit = diagnostics.auditSquad(
        riders: [riderHealthy, riderWarn, riderOts],
        trackers: {
          'r_ok': const RiderBurnoutTrackerState(
            riderId: 'r_ok',
            seasonRaceDaysCount: 30,
          ),
          'r_warn': const RiderBurnoutTrackerState(
            riderId: 'r_warn',
            consecutiveDeepNegativeTsbDays: 8,
            seasonRaceDaysCount: 70,
            recentTsbHistory: [-37.0],
          ),
          'r_ots': const RiderBurnoutTrackerState(
            riderId: 'r_ots',
            consecutiveDeepNegativeTsbDays: 16,
            seasonRaceDaysCount: 88,
            parasympatheticSyndromeActive: true,
            recentTsbHistory: [-42.0],
          ),
        },
      );

      expect(audit.totalRidersEvaluated, 3);
      expect(audit.affectedRidersCount, 1);
      expect(audit.warningRidersCount, 1);
      expect(audit.healthyRidersCount, 1);
      expect(audit.reports.first.riderId, 'r_ots');
      expect(audit.reports.last.riderId, 'r_ok');
    });

    test('serializacja JSON RiderBurnoutTrackerState i OvertrainingDiagnosisReport', () {
      final rider = _buildTestRider(ctl: 60.0, atl: 100.0);
      final report = diagnostics.evaluateRider(
        rider: rider,
        consecutiveDaysBelowTsbLimit: 16,
        seasonRaceDays: 87,
        evaluationDate: DateTime(2026, 8, 12),
      );
      final restoredReport =
          OvertrainingDiagnosisReport.fromJson(report.toJson());
      expect(restoredReport.riderId, report.riderId);
      expect(restoredReport.effectiveMaxHrBpm, report.effectiveMaxHrBpm);
      expect(restoredReport.effectiveFtpWatts, report.effectiveFtpWatts);
      expect(restoredReport.triggerReason, report.triggerReason);

      final tracker = RiderBurnoutTrackerState(
        riderId: 'rider_1',
        consecutiveDeepNegativeTsbDays: 16,
        seasonRaceDaysCount: 87,
        parasympatheticSyndromeActive: true,
        recoveryDaysCompleted: 2,
        lastEvaluatedDate: DateTime(2026, 8, 12),
        recentTsbHistory: const [-36.5, -39.0],
      );
      final restoredTracker =
          RiderBurnoutTrackerState.fromJson(tracker.toJson());
      expect(restoredTracker, tracker);
    });
  });

  group('OvertrainingAndBurnoutDiagnosticsPanel - responsywność i interakcje', () {
    for (final size in const [
      Size(390, 844),
      Size(1024, 768),
      Size(1600, 900),
    ]) {
      testWidgets(
          'renderuje bez przepełnień przy ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final r1 = _buildTestRider(
          id: 'r1',
          firstName: 'Tadej',
          lastName: 'Kowalski',
          ctl: 65,
          atl: 115,
        );
        final r2 = _buildTestRider(
          id: 'r2',
          firstName: 'Filip',
          lastName: 'Nowak',
          ctl: 85,
          atl: 85,
        );

        final summary = diagnostics.auditSquad(
          riders: [r1, r2],
          trackers: const {
            'r1': RiderBurnoutTrackerState(
              riderId: 'r1',
              consecutiveDeepNegativeTsbDays: 16,
              seasonRaceDaysCount: 88,
              parasympatheticSyndromeActive: true,
              recentTsbHistory: [-42.0],
            ),
            'r2': RiderBurnoutTrackerState(
              riderId: 'r2',
              seasonRaceDaysCount: 35,
              recentTsbHistory: [0.0],
            ),
          },
        );

        OvertrainingDiagnosisReport? triggeredReport;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: OvertrainingAndBurnoutDiagnosticsPanel(
                  auditSummary: summary,
                  onApplyRecoveryProtocol: (r) {
                    triggeredReport = r;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Tadej Kowalski'), findsOneWidget);
        expect(find.text('Filip Nowak'), findsOneWidget);

        await tester.tap(find.text('Przetrenowanie (OTS)'));
        await tester.pump(const Duration(milliseconds: 250));
        expect(find.text('Tadej Kowalski'), findsOneWidget);
        expect(find.text('Filip Nowak'), findsNothing);

        final recoveryBtn = find.textContaining('Zastosuj Regenerację');
        expect(recoveryBtn, findsOneWidget);
        await tester.tap(recoveryBtn);
        await tester.pump(const Duration(milliseconds: 250));
        expect(triggeredReport?.riderId, 'r1');
      });
    }
  });
}
