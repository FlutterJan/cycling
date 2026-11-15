import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/core/theme/app_theme.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_appearance.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/models/rider/rider_physiology.dart';
import 'package:pro_peloton_manager/models/rider/rider_power_profile.dart';
import 'package:pro_peloton_manager/models/rider/rider_skills.dart';
import 'package:pro_peloton_manager/ui/widgets/rider_comparison_side_by_side_modal.dart';

Rider _buildTestRider({
  required String id,
  required String firstName,
  required String lastName,
  required String iso,
  required RiderSpecialization spec,
  required int ftpWatts,
  required double weightKg,
  required int wPrimeJoules,
  required double vo2Max,
  required int cobbles,
}) {
  return Rider(
    id: id,
    firstName: firstName,
    lastName: lastName,
    nationalityIso: iso,
    birthDate: DateTime(1998, 5, 14),
    potential: 92,
    specialization: spec,
    physiology: RiderPhysiology(
      heightCm: 178,
      weightKg: weightKg,
      bodyFatPercentage: 6.5,
      ftpWatts: ftpWatts,
      wPrimeJoules: wPrimeJoules,
      vo2Max: vo2Max,
      maxHr: 192,
      restingHr: 38,
      lactateThresholdHr: 174,
      recoveryRate: 84.5,
      glycogenCapacityGrams: 620,
    ),
    powerProfile: RiderPowerProfile(
      watts5s: (ftpWatts * 3.1).round(),
      watts15s: (ftpWatts * 2.5).round(),
      watts30s: (ftpWatts * 2.0).round(),
      watts1m: (ftpWatts * 1.65).round(),
      watts3m: (ftpWatts * 1.28).round(),
      watts5m: (ftpWatts * 1.18).round(),
      watts20m: (ftpWatts * 1.05).round(),
      watts60m: ftpWatts,
    ),
    skills: RiderSkills(
      cobbles: cobbles,
      descending: 82,
      bikeHandling: 86,
      aeroPositioning: 80,
      draftingEfficiency: 84,
      raceIq: 88,
      rainResistance: 79,
      heatTolerance: 77,
      timeTrialPositioning: 83,
    ),
    appearance: const RiderAppearance(
      faceShapeIndex: 0,
      skinToneHex: '#E8B89A',
      hairStyleIndex: 1,
      hairColorHex: '#3B2F2F',
      facialHairIndex: 0,
      glassesModelId: 'aero_pro',
      glassesLensColorHex: '#00E5FF',
      helmetModelId: 'aero_shell',
      shoeColorHex: '#FFFFFF',
      sockHeightProportion: 0.65,
      bodyBuildType: BodyBuildType.allRounder,
    ),
    contract: const RiderContract(
      teamId: 'team_test',
      role: RiderRole.teamLeader,
      monthlySalaryEur: 120000,
      signingBonusEur: 250000,
      winBonusEur: 15000,
      releaseClauseEur: 4500000,
      contractEndYear: 2028,
      morale: 88.0,
      leaderLoyalty: 85.0,
      requiredRacesIds: [],
    ),
    health: const RiderHealth(
      acuteTrainingLoad: 55,
      chronicTrainingLoad: 78,
    ),
    careerPointsUci: 2850,
  );
}

void main() {
  final riders = [
    _buildTestRider(
      id: 'r1',
      firstName: 'Tadej',
      lastName: 'Pogacar',
      iso: 'SLO',
      spec: RiderSpecialization.gcClimber,
      ftpWatts: 420,
      weightKg: 66.0,
      wPrimeJoules: 26500,
      vo2Max: 89.2,
      cobbles: 85,
    ),
    _buildTestRider(
      id: 'r2',
      firstName: 'Jonas',
      lastName: 'Vingegaard',
      iso: 'DEN',
      spec: RiderSpecialization.pureClimber,
      ftpWatts: 405,
      weightKg: 60.0,
      wPrimeJoules: 22000,
      vo2Max: 91.0,
      cobbles: 72,
    ),
    _buildTestRider(
      id: 'r3',
      firstName: 'Mathieu',
      lastName: 'Van der Poel',
      iso: 'NED',
      spec: RiderSpecialization.classicCobbles,
      ftpWatts: 438,
      weightKg: 75.0,
      wPrimeJoules: 30500,
      vo2Max: 86.0,
      cobbles: 97,
    ),
  ];

  Widget wrapForSize(Size size, List<Rider> testRiders) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: RiderComparisonSideBySideModal(riders: testRiders),
            ),
          ),
        ),
      ),
    );
  }

  for (final size in const [
    Size(390, 844),
    Size(1024, 768),
    Size(1600, 900),
  ]) {
    testWidgets(
      'renders 3 riders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(wrapForSize(size, riders));
        await tester.pumpAndSettle();

        expect(find.text('Porównanie Kolarzy'), findsOneWidget);
        expect(find.text('Bezwzględne (W)'), findsOneWidget);
        expect(find.text('Względne (W/kg)'), findsOneWidget);
        expect(find.text('FTP (W)'), findsOneWidget);
        expect(find.text('Cobbles'), findsOneWidget);
        expect(find.text('Recovery Rate'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('toggles between W and W/kg and supports 2 riders',
      (tester) async {
    const size = Size(1024, 768);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrapForSize(size, riders.take(2).toList()));
    await tester.pumpAndSettle();

    expect(find.text('Krzywa Mocy (W)'), findsOneWidget);
    expect(find.text('FTP (W)'), findsOneWidget);

    await tester.tap(find.text('Względne (W/kg)'));
    await tester.pumpAndSettle();

    expect(find.text('Krzywa Mocy (W/kg)'), findsOneWidget);
    expect(find.text('FTP (W/kg)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
