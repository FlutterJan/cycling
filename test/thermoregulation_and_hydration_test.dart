// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/peloton/ice_socks_and_water_dousing_mechanics.dart';
import 'package:pro_peloton_manager/engine/physics/core_body_temperature_thermoregulation.dart';
import 'package:pro_peloton_manager/engine/physics/sweat_sodium_electrolyte_depletion.dart';

void main() {
  group('CoreBodyTemperatureThermoregulation — podjazd w 36 °C', () {
    test(
      'temperatura głęboka ciała rośnie podczas intensywnego podjazdu w 36 °C',
      () {
        var state = const ThermoregulationState(
          coreBodyTemperatureCelsius: 37.2,
          skinTemperatureCelsius: 34.5,
        );

        const climbInput = ThermoregulationStepInput(
          powerWatts: 390.0,
          airSpeedMps: 5.2, // ~18.7 km/h na stromym podjeździe
          ambientTemperatureCelsius: 36.0,
          relativeHumidity: 0.60,
          deltaTimeSeconds: 10.0,
          riderMassKg: 66.0,
          hydrationLevel: 0.85,
        );

        ThermoregulationStepResult? lastResult;
        // 35 minut podjazdu (210 kroków po 10 s)
        for (int i = 0; i < 210; i++) {
          lastResult = CoreBodyTemperatureThermoregulation.step(
            currentState: state,
            input: climbInput,
          );
          state = lastResult.updatedState;
        }

        expect(lastResult, isNotNull);
        expect(state.coreBodyTemperatureCelsius, greaterThan(38.8));
        expect(state.cumulativeSweatLossMl, greaterThan(500.0));
        expect(
          state.thermalZone == CoreThermalZone.highThermalStrain ||
              state.thermalZone == CoreThermalZone.hyperthermicCollapse,
          isTrue,
        );
      },
    );

    test(
      'przekroczenie 39.2 °C wywołuje spadek mocy maksymalnej i dryf tętna +12 BPM',
      () {
        var state = const ThermoregulationState(
          coreBodyTemperatureCelsius: 39.15,
          skinTemperatureCelsius: 37.5,
        );

        const extremeClimbInput = ThermoregulationStepInput(
          powerWatts: 420.0,
          airSpeedMps: 4.5,
          ambientTemperatureCelsius: 36.0,
          relativeHumidity: 0.75,
          deltaTimeSeconds: 10.0,
          riderMassKg: 65.0,
          hydrationLevel: 0.60,
        );

        ThermoregulationStepResult? result;
        for (int i = 0; i < 60; i++) {
          result = CoreBodyTemperatureThermoregulation.step(
            currentState: state,
            input: extremeClimbInput,
          );
          state = result.updatedState;
        }

        expect(state.coreBodyTemperatureCelsius, greaterThan(39.2));
        expect(state.isAboveCriticalThreshold, isTrue);
        expect(state.thermalZone, CoreThermalZone.hyperthermicCollapse);
        expect(result!.maxPowerMultiplier, lessThan(1.0));
        expect(result.heartRateDriftBpm, closeTo(12.0, 1e-6));
      },
    );

    test(
      'peleryna przeciwdeszczowa ogranicza parowanie i przyspiesza przegrzanie',
      () {
        const initial = ThermoregulationState(
          coreBodyTemperatureCelsius: 37.5,
          skinTemperatureCelsius: 34.5,
        );

        var openJerseyState = initial;
        var rainJacketState = initial;

        for (int i = 0; i < 90; i++) {
          openJerseyState = CoreBodyTemperatureThermoregulation.step(
            currentState: openJerseyState,
            input: const ThermoregulationStepInput(
              powerWatts: 340.0,
              airSpeedMps: 6.0,
              ambientTemperatureCelsius: 36.0,
              relativeHumidity: 0.50,
              deltaTimeSeconds: 10.0,
              wearingRainJacket: false,
            ),
          ).updatedState;

          rainJacketState = CoreBodyTemperatureThermoregulation.step(
            currentState: rainJacketState,
            input: const ThermoregulationStepInput(
              powerWatts: 340.0,
              airSpeedMps: 6.0,
              ambientTemperatureCelsius: 36.0,
              relativeHumidity: 0.50,
              deltaTimeSeconds: 10.0,
              wearingRainJacket: true,
            ),
          ).updatedState;
        }

        expect(
          rainJacketState.coreBodyTemperatureCelsius,
          greaterThan(openJerseyState.coreBodyTemperatureCelsius),
        );
      },
    );
  });

  group('IceSocksAndWaterDousingMechanics — chłodzenie Ice Sock i wodą', () {
    test(
      'natychmiastowe użycie woreczka z lodem (Ice Sock) obniża temperaturę o 0.4 °C na 15 minut',
      () {
        const initialState = RiderHeatCoolingState(
          riderId: 'leader_1',
          coreBodyTemperatureCelsius: 39.1,
          ambientTemperatureCelsius: 36.0,
          iceSocksAvailableInTeamCar: 4,
          bidonsAvailable: 2,
        );

        final outcome = IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(
          initialState,
          immediateDelivery: true,
        );

        expect(outcome.accepted, isTrue);
        expect(outcome.actionType, CoolingActionType.iceSock);
        expect(outcome.immediateTempDropCelsius, closeTo(0.4, 1e-6));
        expect(outcome.activeDurationSeconds, closeTo(900.0, 1e-6));
        expect(
          outcome.updatedState.coreBodyTemperatureCelsius,
          closeTo(38.7, 1e-6),
        );
        expect(outcome.updatedState.isIceSockActive, isTrue);
        expect(outcome.updatedState.iceSocksAvailableInTeamCar, 3);
        expect(outcome.updatedState.iceSocksUsedCount, 1);
        expect(outcome.updatedState.status, CoolingOrderStatus.activeCooling);
      },
    );

    test(
      'zjazd do wozu technicznego po Ice Sock dostarcza lód po upływie czasu dojazdu',
      () {
        const initialState = RiderHeatCoolingState(
          riderId: 'leader_1',
          coreBodyTemperatureCelsius: 39.0,
          ambientTemperatureCelsius: 36.0,
          iceSocksAvailableInTeamCar: 2,
        );

        final order = IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(
          initialState,
          immediateDelivery: false,
          fetchDurationSeconds: 25.0,
        );

        expect(order.accepted, isTrue);
        expect(order.immediateTempDropCelsius, 0.0);
        expect(order.updatedState.status, CoolingOrderStatus.enRouteToTeamCar);

        final step1 = IceSocksAndWaterDousingMechanics.step(
          order.updatedState,
          deltaTimeSeconds: 15.0,
        );
        expect(step1.didActivateIceSock, isFalse);
        expect(step1.updatedState.isFetchingIceSockFromCar, isTrue);
        expect(step1.externalCoolingWatts, 0.0);

        final step2 = IceSocksAndWaterDousingMechanics.step(
          step1.updatedState,
          deltaTimeSeconds: 10.0,
        );
        expect(step2.didActivateIceSock, isTrue);
        expect(step2.stepCoolingDropCelsius, closeTo(-0.4, 1e-6));
        expect(
          step2.updatedState.coreBodyTemperatureCelsius,
          closeTo(38.6, 1e-6),
        );
        expect(
          step2.externalCoolingWatts,
          closeTo(
            IceSocksAndWaterDousingMechanics.iceSockCoolingPowerWatts,
            1e-6,
          ),
        );
      },
    );

    test(
      'polanie głowy wodą z bidonu obniża temperaturę o 0.4 °C i zużywa 1 bidon',
      () {
        const initialState = RiderHeatCoolingState(
          riderId: 'leader_1',
          coreBodyTemperatureCelsius: 38.9,
          ambientTemperatureCelsius: 36.0,
          bidonsAvailable: 2,
        );

        final outcome =
            IceSocksAndWaterDousingMechanics.douseHeadWithWater(initialState);

        expect(outcome.accepted, isTrue);
        expect(outcome.actionType, CoolingActionType.waterDouse);
        expect(outcome.immediateTempDropCelsius, closeTo(0.4, 1e-6));
        expect(
          outcome.updatedState.coreBodyTemperatureCelsius,
          closeTo(38.5, 1e-6),
        );
        expect(outcome.updatedState.isWaterDouseActive, isTrue);
        expect(outcome.updatedState.bidonsAvailable, 1);
        expect(outcome.updatedState.waterDousesUsedCount, 1);

        final stepResult = IceSocksAndWaterDousingMechanics.step(
          outcome.updatedState,
          deltaTimeSeconds: 1.0,
        );
        expect(
          stepResult.externalCoolingWatts,
          closeTo(
            IceSocksAndWaterDousingMechanics.waterDouseCoolingPowerWatts,
            1e-6,
          ),
        );
      },
    );

    test(
      'połączenie Ice Sock oraz polania wodą daje łącznie 165 W chłodzenia zewnętrznego i hamuje wzrost temperatury na podjeździe w 36 °C',
      () {
        // Najpierw rozgrzewamy kolarza na podjeździe w 36 °C.
        var thermoState = const ThermoregulationState(
          coreBodyTemperatureCelsius: 37.3,
          skinTemperatureCelsius: 34.5,
        );
        const climbInput = ThermoregulationStepInput(
          powerWatts: 370.0,
          airSpeedMps: 5.5,
          ambientTemperatureCelsius: 36.0,
          relativeHumidity: 0.55,
          deltaTimeSeconds: 10.0,
          riderMassKg: 68.0,
        );

        for (int i = 0; i < 150; i++) {
          thermoState = CoreBodyTemperatureThermoregulation.step(
            currentState: thermoState,
            input: climbInput,
          ).updatedState;
        }
        final heatedCoreTemp = thermoState.coreBodyTemperatureCelsius;
        expect(heatedCoreTemp, greaterThan(38.3));

        // Aktywujemy Ice Sock + Water Douse.
        var coolingState = RiderHeatCoolingState(
          riderId: 'leader_1',
          coreBodyTemperatureCelsius: heatedCoreTemp,
          ambientTemperatureCelsius: 36.0,
          iceSocksAvailableInTeamCar: 3,
          bidonsAvailable: 2,
        );
        final iceOutcome =
            IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(
          coolingState,
          immediateDelivery: true,
        );
        coolingState = iceOutcome.updatedState;
        final waterOutcome =
            IceSocksAndWaterDousingMechanics.douseHeadWithWater(coolingState);
        coolingState = waterOutcome.updatedState;

        expect(
          coolingState.activeTemperatureReductionCelsius,
          closeTo(
            IceSocksAndWaterDousingMechanics.combinedCoolingDropCelsius,
            1e-6,
          ),
        );

        // Porównujemy dalszą jazdę z chłodzeniem vs bez chłodzenia przez 10 minut.
        var uncooledThermo = thermoState;
        var cooledThermo = thermoState.copyWith(
          coreBodyTemperatureCelsius:
              thermoState.coreBodyTemperatureCelsius - 0.65,
        );

        for (int i = 0; i < 60; i++) {
          final coolingStep = IceSocksAndWaterDousingMechanics.step(
            coolingState,
            deltaTimeSeconds: 10.0,
          );
          coolingState = coolingStep.updatedState;
          expect(coolingStep.externalCoolingWatts, closeTo(165.0, 1e-6));

          uncooledThermo = CoreBodyTemperatureThermoregulation.step(
            currentState: uncooledThermo,
            input: climbInput,
          ).updatedState;

          cooledThermo = CoreBodyTemperatureThermoregulation.step(
            currentState: cooledThermo,
            input: ThermoregulationStepInput(
              powerWatts: climbInput.powerWatts,
              airSpeedMps: climbInput.airSpeedMps,
              ambientTemperatureCelsius: climbInput.ambientTemperatureCelsius,
              relativeHumidity: climbInput.relativeHumidity,
              deltaTimeSeconds: climbInput.deltaTimeSeconds,
              riderMassKg: climbInput.riderMassKg,
              externalCoolingWatts: coolingStep.externalCoolingWatts,
            ),
          ).updatedState;
        }

        expect(
          cooledThermo.coreBodyTemperatureCelsius,
          lessThan(uncooledThermo.coreBodyTemperatureCelsius),
        );
        expect(
          uncooledThermo.coreBodyTemperatureCelsius -
              cooledThermo.coreBodyTemperatureCelsius,
          greaterThan(0.5),
        );
      },
    );

    test(
      'wygasanie efektu po 15 minutach (900 s) oraz blokady w strefie ostatnich 20 km i przy pustych bidonach',
      () {
        const closedCarZoneState = RiderHeatCoolingState(
          riderId: 'leader_2',
          coreBodyTemperatureCelsius: 38.9,
          ambientTemperatureCelsius: 36.0,
          isTeamCarZoneClosed: true,
          bidonsAvailable: 0,
        );

        final rejectedIce =
            IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(
          closedCarZoneState,
          immediateDelivery: true,
        );
        expect(rejectedIce.accepted, isFalse);
        expect(rejectedIce.rejectionReasonPl, isNotNull);

        final rejectedWater =
            IceSocksAndWaterDousingMechanics.douseHeadWithWater(
          closedCarZoneState,
        );
        expect(rejectedWater.accepted, isFalse);
        expect(rejectedWater.rejectionReasonPl, isNotNull);
        expect(closedCarZoneState.status, CoolingOrderStatus.unavailable);

        // Wygasanie po 900 s.
        const activeState = RiderHeatCoolingState(
          riderId: 'leader_3',
          coreBodyTemperatureCelsius: 38.5,
          ambientTemperatureCelsius: 36.0,
          iceSockRemainingSeconds: 900.0,
          waterDouseRemainingSeconds: 900.0,
        );
        final expiredStep = IceSocksAndWaterDousingMechanics.step(
          activeState,
          deltaTimeSeconds: 900.0,
        );
        expect(expiredStep.didExpireIceSock, isTrue);
        expect(expiredStep.didExpireWaterDouse, isTrue);
        expect(expiredStep.externalCoolingWatts, 0.0);
        expect(expiredStep.updatedState.isCoolingActive, isFalse);
      },
    );
  });

  group('SweatSodiumElectrolyteDepletion — nawodnienie i elektrolity w 36 °C', () {
    test(
      'brak nawadniania i tabletek elektrolitowych w 36 °C prowadzi do odwodnienia >3% i skurczów',
      () {
        final profile = RiderSweatProfile(
          baseSweatRateLitersPerHour: 1.8,
          sweatSodiumConcentrationMgPerL: 1200.0,
          riderMassKg: 66.0,
        );
        var state = SweatElectrolyteState.initial(profile);

        SweatElectrolyteStepResult? lastResult;
        // 90 minut jazdy w upale bez picia (90 kroków po 60 s)
        for (int i = 0; i < 90; i++) {
          lastResult = SweatSodiumElectrolyteDepletion.step(
            profile: profile,
            currentState: state,
            input: const SweatElectrolyteStepInput(
              deltaTimeSeconds: 60.0,
              powerWatts: 340.0,
              ftpWatts: 390.0,
              ambientTemperatureCelsius: 36.0,
              relativeHumidity: 0.55,
              coreBodyTemperatureCelsius: 38.9,
              distanceToFinishMeters: 5000.0,
              isSprintingOrHighTorque: true,
            ),
          );
          state = lastResult.updatedState;
        }

        expect(lastResult, isNotNull);
        expect(lastResult!.dehydrationPercent, greaterThan(3.0));
        expect(state.hasMuscleCramps, isTrue);
        expect(
          lastResult.status,
          HydrationElectrolyteStatus.muscleCramps,
        );
      },
    );

    test(
      'regularne picie izotoników i tabletka elektrolitowa zapobiegają skurczom w 36 °C',
      () {
        final profile = RiderSweatProfile(
          baseSweatRateLitersPerHour: 1.6,
          sweatSodiumConcentrationMgPerL: 1000.0,
          riderMassKg: 68.0,
        );
        var state = SweatElectrolyteState.initial(profile);

        SweatElectrolyteStepResult? lastResult;
        // 90 minut jazdy z bidonem izotonicznym co 15 minut i tabletką w 40. minucie
        for (int minute = 1; minute <= 90; minute++) {
          final intakes = <ElectrolyteIntakeEvent>[];
          if (minute % 15 == 0) {
            intakes.add(ElectrolyteIntakeEvent.isotonicBidon(volumeMl: 500.0));
          }
          if (minute == 40) {
            intakes.add(
              ElectrolyteIntakeEvent.electrolyteTablet(fluidMl: 250.0),
            );
          }

          lastResult = SweatSodiumElectrolyteDepletion.step(
            profile: profile,
            currentState: state,
            input: SweatElectrolyteStepInput(
              deltaTimeSeconds: 60.0,
              powerWatts: 340.0,
              ftpWatts: 390.0,
              ambientTemperatureCelsius: 36.0,
              relativeHumidity: 0.55,
              coreBodyTemperatureCelsius: 38.4,
              distanceToFinishMeters: 5000.0,
              isSprintingOrHighTorque: true,
              intakes: intakes,
            ),
          );
          state = lastResult.updatedState;
        }

        expect(lastResult, isNotNull);
        expect(lastResult!.dehydrationPercent, lessThan(2.0));
        expect(state.hasMuscleCramps, isFalse);
        expect(state.electrolyteTabletsTaken, 1);
      },
    );
  });
}
