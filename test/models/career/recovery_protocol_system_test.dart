// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/models/career/recovery_protocol_system.dart';
import 'package:pro_peloton_manager/models/rider/rider.dart';
import 'package:pro_peloton_manager/models/rider/rider_contract.dart';
import 'package:pro_peloton_manager/models/rider/rider_health.dart';
import 'package:pro_peloton_manager/services/generators/rider_procedural_generator.dart';

void main() {
  Rider createSampleRider({
    double atl = 80.0,
    double ctl = 100.0,
    int heatTolerance = 72,
    Injury? injury,
  }) {
    final base = RiderProceduralGenerator.generateRider(
      specialization: RiderSpecialization.gcClimber,
      role: RiderRole.teamLeader,
      targetOverallRating: 90,
    );
    return base.copyWith(
      id: 'rider-tadej-1',
      firstName: 'Tadej',
      lastName: 'Pogačar-Type',
      physiology: base.physiology.copyWith(
        fatigue: atl,
        form: ctl,
      ),
      skills: base.skills.copyWith(
        heatTolerance: heatTolerance,
      ),
      health: base.health.copyWith(
        acuteTrainingLoad: atl,
        chronicTrainingLoad: ctl,
        currentInjury: injury,
        clearInjury: injury == null,
      ),
    );
  }

  group('RecoveryProtocolSystem - 1. Nogawki Kompresyjne (Drenaż Limfatyczny)', () {
    test('Drenaż limfatyczny obniża ATL o ~10% i poprawia wskaźnik TSB', () {
      final rider = createSampleRider(atl: 80.0, ctl: 100.0);
      expect(rider.health.trainingStressBalance, equals(20.0)); // 100 - 80 = +20

      final (updatedRider, report) = RecoveryProtocolSystem.applyProtocol(
        rider: rider,
        protocolType: RecoveryProtocolType.pneumaticCompressionBoots,
        teamDoctorSkillLevel: 70,
      );

      // Obniżenie ATL o około 10% (z 80 do ~71-72)
      expect(updatedRider.health.acuteTrainingLoad, lessThan(80.0));
      expect(updatedRider.health.acuteTrainingLoad, closeTo(71.2, 1.5));
      expect(updatedRider.physiology.fatigue, equals(updatedRider.health.acuteTrainingLoad));
      expect(report.atlReduced, closeTo(8.8, 1.5));

      // Poprawa świeżości TSB
      expect(updatedRider.health.trainingStressBalance, greaterThan(20.0));
      expect(report.protocol.isMobileBusCompatible, isTrue);
      expect(report.medicalSummary, contains('Drenaż limfatyczny'));
    });
  });

  group('RecoveryProtocolSystem - 2. Krioterapia i Komora Hiperbaryczna (HBOT)', () {
    test('Krioterapia (-110°C) zdejmuje ok. 18% zmęczenia ATL', () {
      final rider = createSampleRider(atl: 90.0, ctl: 100.0);

      final (updatedRider, report) = RecoveryProtocolSystem.applyProtocol(
        rider: rider,
        protocolType: RecoveryProtocolType.wholeBodyCryotherapy,
        teamDoctorSkillLevel: 80,
      );

      // Spadek ATL o ~18% (z 90 do ~72-74)
      expect(updatedRider.health.acuteTrainingLoad, lessThan(76.0));
      expect(report.atlReduced, greaterThan(15.0));
      expect(report.protocol.domsReliefPercent, equals(40.0));
      expect(report.medicalSummary, contains('Krioterapia'));
    });

    test('Komora hiperbaryczna (HBOT) zapewnia najsilniejszą redukcję ATL (~22%) i bolesności DOMS', () {
      final rider = createSampleRider(atl: 100.0, ctl: 100.0);

      final (updatedRider, report) = RecoveryProtocolSystem.applyProtocol(
        rider: rider,
        protocolType: RecoveryProtocolType.hyperbaricOxygenTherapy,
        teamDoctorSkillLevel: 90,
      );

      // Spadek ATL o ponad 20 pkt
      expect(report.atlReduced, greaterThan(20.0));
      expect(updatedRider.health.acuteTrainingLoad, lessThan(80.0));
      expect(report.protocol.domsReliefPercent, equals(50.0));
      expect(report.medicalSummary, contains('Komora hiperbaryczna'));
    });
  });

  group('RecoveryProtocolSystem - 3. Sauna Sucha (Adaptacja Cieplna & heatTolerance)', () {
    test('Sauna sucha podnosi statystykę heatTolerance kolarza pod gorące etapy Touru', () {
      final rider = createSampleRider(atl: 60.0, heatTolerance: 72);

      final (updatedRider, report) = RecoveryProtocolSystem.applyProtocol(
        rider: rider,
        protocolType: RecoveryProtocolType.drySaunaHeatAcclimation,
        teamDoctorSkillLevel: 75,
      );

      // heatTolerance wzrasta (np. z 72 do 74)
      expect(updatedRider.skills.heatTolerance, greaterThan(72));
      expect(report.heatToleranceGainedOrDelta, greaterThanOrEqualTo(1));
      expect(report.protocol.plasmaVolumeExpansionPercent, equals(6.0));
      expect(report.medicalSummary, contains('Heat Tolerance'));
      expect(report.physiologicalNotes.any((n) => n.contains('osocza')), isTrue);
    });
  });

  group('RecoveryProtocolSystem - 4. Opatrunki Hydrokoloidowe na Szlify (Road Rash)', () {
    test('Opatrunki hydrokoloidowe skracają czas rekonwalescencji szlifu powypadkowego o 2 dni', () {
      const roadRashInjury = Injury(
        name: 'Asfaltowe szlify biodra i łokcia',
        type: InjuryType.roadRash,
        daysRemaining: 4,
        trainingAllowed: true,
      );

      final injuredRider = createSampleRider(atl: 75.0, injury: roadRashInjury);
      expect(injuredRider.health.recoveryDaysRemaining, equals(4));

      // Pierwsza aplikacja opatrunków hydrokoloidowych
      final (riderAfterCare1, report1) = RecoveryProtocolSystem.applyProtocol(
        rider: injuredRider,
        protocolType: RecoveryProtocolType.hydrocolloidRoadRashCare,
      );

      expect(report1.hadRoadRash, isTrue);
      expect(riderAfterCare1.health.currentInjury, isNotNull);
      expect(riderAfterCare1.health.currentInjury!.daysRemaining, equals(2)); // 4 - 2 = 2 dni
      expect(report1.isRoadRashFullyHealed, isFalse);
      expect(report1.protocol.sleepQualityBonusPercent, equals(30.0));

      // Druga aplikacja opatrunków na kolejny dzień
      final (riderAfterCare2, report2) = RecoveryProtocolSystem.applyProtocol(
        rider: riderAfterCare1,
        protocolType: RecoveryProtocolType.hydrocolloidRoadRashCare,
      );

      // Szlif został całkowicie wyleczony!
      expect(riderAfterCare2.health.currentInjury, isNull);
      expect(report2.isRoadRashFullyHealed, isTrue);
      expect(report2.medicalSummary, contains('całkowicie wyleczyły szlif'));
    });
  });

  group('RecoveryProtocolSystem - Rekomendacje Medyczne i Infrastruktura', () {
    test('recommendProtocols zaleca hydrokoloidy po kraksie i HBOT po etapie wysokogórskim', () {
      final riderWithCrash = createSampleRider(
        atl: 95.0,
        injury: const Injury(
          name: 'Szlif',
          type: InjuryType.roadRash,
          daysRemaining: 3,
          trainingAllowed: true,
        ),
      );

      final recs = RecoveryProtocolSystem.recommendProtocols(
        rider: riderWithCrash,
        stageTss: 280.0, // Ciężki etap górski
        hadCrash: true,
        upcomingHotStage: true,
        upcomingTemperatureCelsius: 34.0,
      );

      expect(recs.contains(RecoveryProtocolType.hydrocolloidRoadRashCare), isTrue);
      expect(recs.contains(RecoveryProtocolType.activeCoolDownRollers), isTrue);
      expect(recs.contains(RecoveryProtocolType.hyperbaricOxygenTherapy), isTrue);
      expect(recs.contains(RecoveryProtocolType.drySaunaHeatAcclimation), isTrue);
    });

    test('TeamRecoveryCenterFacilities poprawnie weryfikuje dostępność procedur', () {
      final proTeam = TeamRecoveryCenterFacilities.standardProTeam();
      final eliteWorldTour = TeamRecoveryCenterFacilities.worldTourElite();

      expect(proTeam.canExecuteProtocol(RecoveryProtocolType.pneumaticCompressionBoots), isTrue);
      expect(proTeam.canExecuteProtocol(RecoveryProtocolType.wholeBodyCryotherapy), isFalse);
      expect(proTeam.canExecuteProtocol(RecoveryProtocolType.hyperbaricOxygenTherapy), isFalse);

      expect(eliteWorldTour.canExecuteProtocol(RecoveryProtocolType.wholeBodyCryotherapy), isTrue);
      expect(eliteWorldTour.canExecuteProtocol(RecoveryProtocolType.hyperbaricOxygenTherapy), isTrue);
      expect(eliteWorldTour.canExecuteProtocol(RecoveryProtocolType.drySaunaHeatAcclimation), isTrue);
    });
  });

  group('RecoveryProtocolSystem - Serializacja JSON', () {
    test('Protokoły i infrastruktura serializują się bezstratnie do JSON', () {
      final facilities = TeamRecoveryCenterFacilities.worldTourElite();
      final json = facilities.toJson();
      final restored = TeamRecoveryCenterFacilities.fromJson(json);

      expect(restored.hasCryotherapyChamber, isTrue);
      expect(restored.hasHyperbaricOxygenChamber, isTrue);
      expect(restored.hasDrySaunaFacility, isTrue);

      final protocol = RecoveryProtocolSystem.getProtocol(RecoveryProtocolType.drySaunaHeatAcclimation);
      final protocolJson = protocol.toJson();
      final restoredProtocol = RecoveryProtocol.fromJson(protocolJson);

      expect(restoredProtocol.type, equals(RecoveryProtocolType.drySaunaHeatAcclimation));
      expect(restoredProtocol.heatToleranceGain, equals(2.0));
    });
  });
}

extension on RecoveryProtocolExecutionReport {
  int get heatToleranceGainedOrDelta => heatToleranceDelta;
}
