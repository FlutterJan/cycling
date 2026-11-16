// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Rodzaj interwencji chłodzącej kolarza w warunkach wysokiego stresu cieplnego.
enum CoolingActionType {
  /// Woreczek / skarpeta z lodem (Ice Sock) pobierana z wozu technicznego i wkładana na kark.
  iceSock,

  /// Polewanie głowy i karku wodą z bidonu (Water Douse).
  waterDouse;

  String get labelPl {
    switch (this) {
      case CoolingActionType.iceSock:
        return 'Woreczek z lodem (Ice Sock)';
      case CoolingActionType.waterDouse:
        return 'Polewanie głowy wodą';
    }
  }

  String get shortLabelPl {
    switch (this) {
      case CoolingActionType.iceSock:
        return 'Ice Sock';
      case CoolingActionType.waterDouse:
        return 'Polej wodą';
    }
  }
}

/// Aktualny status operacji chłodzenia kolarza.
enum CoolingOrderStatus {
  /// Brak aktywnego chłodzenia i oczekujących rozkazów.
  idle,

  /// Kolarz lub pomocnik jedzie do wozu technicznego po woreczek z lodem.
  enRouteToTeamCar,

  /// Chłodzenie aktywne (obniżenie temperatury głębokiej o 0.4 °C przez 15 minut).
  activeCooling,

  /// Brak dostępnych zasobów (brak woreczków w wozie lub pusty bidon).
  unavailable,
}

/// Stan mechaniki chłodzenia w upale pojedynczego kolarza podczas etapu.
class RiderHeatCoolingState {
  /// Identyfikator kolarza.
  final String riderId;

  /// Bieżąca temperatura głęboka ciała przed/po interwencji chłodzącej [°C].
  final double coreBodyTemperatureCelsius;

  /// Temperatura otoczenia na trasie [°C].
  final double ambientTemperatureCelsius;

  /// Pozostały czas aktywnego działania woreczka z lodem na karku [s] (max 900 s).
  final double iceSockRemainingSeconds;

  /// Pozostały czas aktywnego efektu polewania głowy wodą [s] (max 900 s).
  final double waterDouseRemainingSeconds;

  /// Czy trwa aktualnie zjazd do wozu technicznego po woreczek z lodem.
  final bool isFetchingIceSockFromCar;

  /// Pozostały czas do odbioru woreczka z lodem z wozu technicznego [s].
  final double carFetchRemainingSeconds;

  /// Liczba woreczków z lodem dostępnych w wozie technicznym dla kolarza.
  final int iceSocksAvailableInTeamCar;

  /// Liczba woreczków z lodem zużytych od startu etapu.
  final int iceSocksUsedCount;

  /// Liczba dostępnych bidonów z wodą w koszykach kolarza (0–2).
  final int bidonsAvailable;

  /// Liczba polewań głowy wodą wykonanych na etapie.
  final int waterDousesUsedCount;

  /// Czy odcinek znajduje się w strefie zakazu obsługi z wozu (ostatnie 20 km UCI).
  final bool isTeamCarZoneClosed;

  const RiderHeatCoolingState({
    required this.riderId,
    this.coreBodyTemperatureCelsius = 37.4,
    this.ambientTemperatureCelsius = 33.0,
    this.iceSockRemainingSeconds = 0.0,
    this.waterDouseRemainingSeconds = 0.0,
    this.isFetchingIceSockFromCar = false,
    this.carFetchRemainingSeconds = 0.0,
    this.iceSocksAvailableInTeamCar = 4,
    this.iceSocksUsedCount = 0,
    this.bidonsAvailable = 2,
    this.waterDousesUsedCount = 0,
    this.isTeamCarZoneClosed = false,
  });

  /// Czy woreczek z lodem aktywnie chłodzi kark kolarza.
  bool get isIceSockActive => iceSockRemainingSeconds > 0.0;

  /// Czy efekt polewania głowy wodą jest aktywny.
  bool get isWaterDouseActive => waterDouseRemainingSeconds > 0.0;

  /// Czy dowolna metoda chłodzenia jest obecnie aktywna.
  bool get isCoolingActive => isIceSockActive || isWaterDouseActive;

  /// Aktualna łączna redukcja temperatury głębokiej ciała wynikająca z aktywnego chłodzenia [°C].
  ///
  /// Pojedyncza metoda obniża temperaturę głęboką o 0.4 °C na 15 minut; jednoczesne
  /// stosowanie obu metod kumuluje efekt do 0.65 °C dla zachowania realizmu fizjologicznego.
  double get activeTemperatureReductionCelsius {
    if (isIceSockActive && isWaterDouseActive) {
      return IceSocksAndWaterDousingMechanics.combinedCoolingDropCelsius;
    }
    if (isIceSockActive || isWaterDouseActive) {
      return IceSocksAndWaterDousingMechanics.coolingTemperatureDropCelsius;
    }
    return 0.0;
  }

  /// Czy można wydać rozkaz pobrania woreczka z lodem z wozu technicznego.
  bool get canOrderIceSock =>
      !isFetchingIceSockFromCar &&
      iceSocksAvailableInTeamCar > 0 &&
      !isTeamCarZoneClosed;

  /// Czy kolarz może natychmiast polać głowę wodą z bidonu.
  bool get canDouseWater => bidonsAvailable > 0;

  /// Bieżący status operacji chłodzenia.
  CoolingOrderStatus get status {
    if (isFetchingIceSockFromCar) {
      return CoolingOrderStatus.enRouteToTeamCar;
    }
    if (isCoolingActive) {
      return CoolingOrderStatus.activeCooling;
    }
    if (!canOrderIceSock && !canDouseWater) {
      return CoolingOrderStatus.unavailable;
    }
    return CoolingOrderStatus.idle;
  }

  /// Pozostały czas najdłużej trwającego aktywnego chłodzenia [s].
  double get maxRemainingCoolingSeconds =>
      math.max(iceSockRemainingSeconds, waterDouseRemainingSeconds);

  RiderHeatCoolingState copyWith({
    String? riderId,
    double? coreBodyTemperatureCelsius,
    double? ambientTemperatureCelsius,
    double? iceSockRemainingSeconds,
    double? waterDouseRemainingSeconds,
    bool? isFetchingIceSockFromCar,
    double? carFetchRemainingSeconds,
    int? iceSocksAvailableInTeamCar,
    int? iceSocksUsedCount,
    int? bidonsAvailable,
    int? waterDousesUsedCount,
    bool? isTeamCarZoneClosed,
  }) {
    return RiderHeatCoolingState(
      riderId: riderId ?? this.riderId,
      coreBodyTemperatureCelsius:
          coreBodyTemperatureCelsius ?? this.coreBodyTemperatureCelsius,
      ambientTemperatureCelsius:
          ambientTemperatureCelsius ?? this.ambientTemperatureCelsius,
      iceSockRemainingSeconds:
          iceSockRemainingSeconds ?? this.iceSockRemainingSeconds,
      waterDouseRemainingSeconds:
          waterDouseRemainingSeconds ?? this.waterDouseRemainingSeconds,
      isFetchingIceSockFromCar:
          isFetchingIceSockFromCar ?? this.isFetchingIceSockFromCar,
      carFetchRemainingSeconds:
          carFetchRemainingSeconds ?? this.carFetchRemainingSeconds,
      iceSocksAvailableInTeamCar:
          iceSocksAvailableInTeamCar ?? this.iceSocksAvailableInTeamCar,
      iceSocksUsedCount: iceSocksUsedCount ?? this.iceSocksUsedCount,
      bidonsAvailable: bidonsAvailable ?? this.bidonsAvailable,
      waterDousesUsedCount: waterDousesUsedCount ?? this.waterDousesUsedCount,
      isTeamCarZoneClosed: isTeamCarZoneClosed ?? this.isTeamCarZoneClosed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riderId': riderId,
      'coreBodyTemperatureCelsius': coreBodyTemperatureCelsius,
      'ambientTemperatureCelsius': ambientTemperatureCelsius,
      'iceSockRemainingSeconds': iceSockRemainingSeconds,
      'waterDouseRemainingSeconds': waterDouseRemainingSeconds,
      'isFetchingIceSockFromCar': isFetchingIceSockFromCar,
      'carFetchRemainingSeconds': carFetchRemainingSeconds,
      'iceSocksAvailableInTeamCar': iceSocksAvailableInTeamCar,
      'iceSocksUsedCount': iceSocksUsedCount,
      'bidonsAvailable': bidonsAvailable,
      'waterDousesUsedCount': waterDousesUsedCount,
      'isTeamCarZoneClosed': isTeamCarZoneClosed,
    };
  }

  factory RiderHeatCoolingState.fromJson(Map<String, dynamic> json) {
    return RiderHeatCoolingState(
      riderId: json['riderId'] as String? ?? 'rider_0',
      coreBodyTemperatureCelsius:
          (json['coreBodyTemperatureCelsius'] as num?)?.toDouble() ?? 37.4,
      ambientTemperatureCelsius:
          (json['ambientTemperatureCelsius'] as num?)?.toDouble() ?? 33.0,
      iceSockRemainingSeconds:
          (json['iceSockRemainingSeconds'] as num?)?.toDouble() ?? 0.0,
      waterDouseRemainingSeconds:
          (json['waterDouseRemainingSeconds'] as num?)?.toDouble() ?? 0.0,
      isFetchingIceSockFromCar:
          json['isFetchingIceSockFromCar'] as bool? ?? false,
      carFetchRemainingSeconds:
          (json['carFetchRemainingSeconds'] as num?)?.toDouble() ?? 0.0,
      iceSocksAvailableInTeamCar:
          (json['iceSocksAvailableInTeamCar'] as num?)?.toInt() ?? 4,
      iceSocksUsedCount: (json['iceSocksUsedCount'] as num?)?.toInt() ?? 0,
      bidonsAvailable: (json['bidonsAvailable'] as num?)?.toInt() ?? 2,
      waterDousesUsedCount:
          (json['waterDousesUsedCount'] as num?)?.toInt() ?? 0,
      isTeamCarZoneClosed: json['isTeamCarZoneClosed'] as bool? ?? false,
    );
  }
}

/// Wynik wydania rozkazu chłodzenia kolarza (`Ice Sock` lub `Water Douse`).
class CoolingOrderOutcome {
  /// Czy rozkaz został przyjęty do realizacji.
  final bool accepted;

  /// Rodzaj zleconej interwencji chłodzącej.
  final CoolingActionType actionType;

  /// Zaktualizowany stan chłodzenia kolarza.
  final RiderHeatCoolingState updatedState;

  /// Natychmiastowe obniżenie temperatury głębokiej ciała [°C] (0.0 jeśli w drodze do auta).
  final double immediateTempDropCelsius;

  /// Czas trwania efektu chłodzącego [s] (900.0 s = 15 minut).
  final double activeDurationSeconds;

  /// Komunikat radiowy w języku polskim.
  final String radioMessagePl;

  /// Powód odrzucenia rozkazu, jeśli [accepted] == false.
  final String? rejectionReasonPl;

  const CoolingOrderOutcome({
    required this.accepted,
    required this.actionType,
    required this.updatedState,
    required this.immediateTempDropCelsius,
    required this.activeDurationSeconds,
    required this.radioMessagePl,
    this.rejectionReasonPl,
  });
}

/// Wynik pojedynczego kroku symulacji mechaniki chłodzenia w upale.
class CoolingStepResult {
  /// Zaktualizowany stan po kroku czasowym.
  final RiderHeatCoolingState updatedState;

  /// Efektywna moc chłodzenia zewnętrznego [W] dla silnika termoregulacji.
  final double externalCoolingWatts;

  /// Zmiana temperatury głębokiej zastosowana w tym kroku (ujemna przy aktywacji) [°C].
  final double stepCoolingDropCelsius;

  /// Czy w tym kroku dostarczono i założono na kark woreczek z lodem z wozu.
  final bool didActivateIceSock;

  /// Czy w tym kroku wygasł efekt woreczka z lodem (po 15 minutach).
  final bool didExpireIceSock;

  /// Czy w tym kroku wygasł efekt polewania wodą (po 15 minutach).
  final bool didExpireWaterDouse;

  /// Opcjonalny komunikat radiowy z wozu technicznego.
  final String? radioNotificationPl;

  const CoolingStepResult({
    required this.updatedState,
    required this.externalCoolingWatts,
    required this.stepCoolingDropCelsius,
    required this.didActivateIceSock,
    required this.didExpireIceSock,
    required this.didExpireWaterDouse,
    this.radioNotificationPl,
  });
}

/// Mechanika chłodzenia kolarzy w upale: woreczki z lodem na kark (`Ice Sock`)
/// pobierane z wozu technicznego oraz polewanie głowy wodą z bidonu (`Water Douse`).
///
/// Każda z interwencji obniża temperaturę głęboką ciała o `0.4 °C` na `15 minut` (900 s),
/// zmniejszając ryzyko hipertermii (> 39.2 °C) i spadku mocy na podjazdach w upale.
class IceSocksAndWaterDousingMechanics {
  IceSocksAndWaterDousingMechanics._();

  /// Obniżenie temperatury głębokiej ciała po zastosowaniu Ice Sock lub Water Douse [°C].
  static const double coolingTemperatureDropCelsius = 0.4;

  /// Skumulowane obniżenie temperatury przy jednoczesnym użyciu obu metod [°C].
  static const double combinedCoolingDropCelsius = 0.65;

  /// Czas utrzymywania się efektu chłodzącego [s] (15 minut = 900 s).
  static const double coolingDurationSeconds = 900.0;

  /// Standardowy czas dojazdu do wozu technicznego i odbioru woreczka z lodem [s].
  static const double defaultTeamCarFetchSeconds = 25.0;

  /// Dodatkowe chłodzenie zewnętrzne [W] z woreczka z lodem przekazywane do termoregulacji.
  static const double iceSockCoolingPowerWatts = 95.0;

  /// Dodatkowe chłodzenie zewnętrzne [W] z parowania wody wylanej na głowę i kark.
  static const double waterDouseCoolingPowerWatts = 70.0;

  /// Próg temperatury otoczenia [°C], powyżej którego zaleca się profilaktyczne chłodzenie.
  static const double heatAdvisoryAmbientCelsius = 28.0;

  /// Próg temperatury głębokiej ciała [°C], przy którym radio sugeruje interwencję.
  static const double recommendedCoolingCoreTempCelsius = 38.6;

  /// Bezpieczna dolna granica temperatury głębokiej ciała [°C].
  static const double minCoreTempCelsius = 36.5;

  /// Maksymalna temperatura głęboka ciała w modelu [°C].
  static const double maxCoreTempCelsius = 40.5;

  /// Wydaje rozkaz pobrania z wozu technicznego woreczka z lodem na kark (`Ice Sock`).
  ///
  /// Jeśli [immediateDelivery] == true (np. pomocnik jest już przy wozie), woreczek
  /// jest zakładany natychmiast, obniżając temperaturę głęboką o `0.4 °C` na `15 minut`.
  /// W przeciwnym razie kolarz spływa do wozu technicznego przez [fetchDurationSeconds].
  static CoolingOrderOutcome orderIceSockFromTeamCar(
    RiderHeatCoolingState state, {
    bool immediateDelivery = false,
    double fetchDurationSeconds = defaultTeamCarFetchSeconds,
  }) {
    if (state.isTeamCarZoneClosed) {
      return CoolingOrderOutcome(
        accepted: false,
        actionType: CoolingActionType.iceSock,
        updatedState: state,
        immediateTempDropCelsius: 0.0,
        activeDurationSeconds: 0.0,
        radioMessagePl:
            'Wóz techniczny zamknięty w strefie ostatnich 20 km — brak możliwości pobrania lodu.',
        rejectionReasonPl: 'Strefa zakazu obsługi z wozu (ostatnie 20 km UCI).',
      );
    }

    if (state.iceSocksAvailableInTeamCar <= 0) {
      return CoolingOrderOutcome(
        accepted: false,
        actionType: CoolingActionType.iceSock,
        updatedState: state,
        immediateTempDropCelsius: 0.0,
        activeDurationSeconds: 0.0,
        radioMessagePl:
            'Brak zapasowych woreczków z lodem w lodówce wozu technicznego!',
        rejectionReasonPl: 'Wyczerpany zapas woreczków z lodem w wozie.',
      );
    }

    if (state.isFetchingIceSockFromCar) {
      return CoolingOrderOutcome(
        accepted: false,
        actionType: CoolingActionType.iceSock,
        updatedState: state,
        immediateTempDropCelsius: 0.0,
        activeDurationSeconds: 0.0,
        radioMessagePl:
            'Kolarz jest już w drodze do wozu technicznego po woreczek z lodem.',
        rejectionReasonPl: 'Rozkaz pobrania lodu jest już w trakcie realizacji.',
      );
    }

    if (immediateDelivery || fetchDurationSeconds <= 0.0) {
      final double drop = state.isIceSockActive ? 0.0 : coolingTemperatureDropCelsius;
      final double newTemp = (state.coreBodyTemperatureCelsius - drop)
          .clamp(minCoreTempCelsius, maxCoreTempCelsius)
          .toDouble();

      final updated = state.copyWith(
        coreBodyTemperatureCelsius: newTemp,
        iceSockRemainingSeconds: coolingDurationSeconds,
        isFetchingIceSockFromCar: false,
        carFetchRemainingSeconds: 0.0,
        iceSocksAvailableInTeamCar: state.iceSocksAvailableInTeamCar - 1,
        iceSocksUsedCount: state.iceSocksUsedCount + 1,
      );

      return CoolingOrderOutcome(
        accepted: true,
        actionType: CoolingActionType.iceSock,
        updatedState: updated,
        immediateTempDropCelsius: drop,
        activeDurationSeconds: coolingDurationSeconds,
        radioMessagePl:
            'Woreczek z lodem (Ice Sock) na karku! Temperatura głęboka obniżona o 0.4 °C na 15 minut.',
      );
    }

    final double safeDuration = math.max(1.0, fetchDurationSeconds);
    final updated = state.copyWith(
      isFetchingIceSockFromCar: true,
      carFetchRemainingSeconds: safeDuration,
    );

    return CoolingOrderOutcome(
      accepted: true,
      actionType: CoolingActionType.iceSock,
      updatedState: updated,
      immediateTempDropCelsius: 0.0,
      activeDurationSeconds: coolingDurationSeconds,
      radioMessagePl:
          'Zjazd do wozu technicznego po woreczek z lodem (${safeDuration.round()} s do odbioru).',
    );
  }

  /// Wydaje rozkaz polania głowy i karku wodą z bidonu (`Water Douse`).
  ///
  /// Zużywa 1 bidon z koszyka kolarza i natychmiast obniża temperaturę głęboką
  /// ciała o `0.4 °C` na `15 minut` (900 s).
  static CoolingOrderOutcome douseHeadWithWater(RiderHeatCoolingState state) {
    if (state.bidonsAvailable <= 0) {
      return CoolingOrderOutcome(
        accepted: false,
        actionType: CoolingActionType.waterDouse,
        updatedState: state,
        immediateTempDropCelsius: 0.0,
        activeDurationSeconds: 0.0,
        radioMessagePl:
            'Puste koszyki! Brak wody w bidonach — najpierw zjedź po zapasy.',
        rejectionReasonPl: 'Brak dostępnych bidonów z wodą.',
      );
    }

    final double drop =
        state.isWaterDouseActive ? 0.0 : coolingTemperatureDropCelsius;
    final double newTemp = (state.coreBodyTemperatureCelsius - drop)
        .clamp(minCoreTempCelsius, maxCoreTempCelsius)
        .toDouble();

    final updated = state.copyWith(
      coreBodyTemperatureCelsius: newTemp,
      waterDouseRemainingSeconds: coolingDurationSeconds,
      bidonsAvailable: state.bidonsAvailable - 1,
      waterDousesUsedCount: state.waterDousesUsedCount + 1,
    );

    return CoolingOrderOutcome(
      accepted: true,
      actionType: CoolingActionType.waterDouse,
      updatedState: updated,
      immediateTempDropCelsius: drop,
      activeDurationSeconds: coolingDurationSeconds,
      radioMessagePl:
          'Polewanie głowy wodą z bidonu! Temperatura głęboka -0.4 °C na 15 minut.',
    );
  }

  /// Aktualizuje stan chłodzenia w pojedynczym kroku czasowym symulacji ([deltaTimeSeconds]).
  ///
  /// Obsługuje dojazd do wozu technicznego, aktywację woreczka z lodem na karku,
  /// odliczanie 15-minutowego okna chłodzenia oraz wylicza moc chłodzenia zewnętrznego [W].
  static CoolingStepResult step(
    RiderHeatCoolingState state, {
    required double deltaTimeSeconds,
  }) {
    final double dt = math.max(0.0, deltaTimeSeconds);
    if (dt == 0.0) {
      return CoolingStepResult(
        updatedState: state,
        externalCoolingWatts: _computeExternalCoolingWatts(state),
        stepCoolingDropCelsius: 0.0,
        didActivateIceSock: false,
        didExpireIceSock: false,
        didExpireWaterDouse: false,
      );
    }

    var current = state;
    bool didActivateIceSock = false;
    double stepCoolingDrop = 0.0;
    String? radioNote;

    // 1. Obsługa trwającego zjazdu do wozu technicznego po Ice Sock.
    if (current.isFetchingIceSockFromCar) {
      final double remainingFetch = current.carFetchRemainingSeconds - dt;
      if (remainingFetch <= 0.0) {
        if (current.iceSocksAvailableInTeamCar > 0) {
          final double drop =
              current.isIceSockActive ? 0.0 : coolingTemperatureDropCelsius;
          final double newTemp = (current.coreBodyTemperatureCelsius - drop)
              .clamp(minCoreTempCelsius, maxCoreTempCelsius)
              .toDouble();

          current = current.copyWith(
            coreBodyTemperatureCelsius: newTemp,
            iceSockRemainingSeconds: coolingDurationSeconds,
            isFetchingIceSockFromCar: false,
            carFetchRemainingSeconds: 0.0,
            iceSocksAvailableInTeamCar: current.iceSocksAvailableInTeamCar - 1,
            iceSocksUsedCount: current.iceSocksUsedCount + 1,
          );
          didActivateIceSock = true;
          stepCoolingDrop = -drop;
          radioNote =
              'Odebrano woreczek z lodem z wozu! Chłodzenie karku -0.4 °C przez 15 min.';
        } else {
          current = current.copyWith(
            isFetchingIceSockFromCar: false,
            carFetchRemainingSeconds: 0.0,
          );
          radioNote = 'Wóz techniczny nie ma już woreczków z lodem.';
        }
      } else {
        current = current.copyWith(carFetchRemainingSeconds: remainingFetch);
      }
    }

    // 2. Odliczanie czasu aktywnego chłodzenia (15 minut = 900 s).
    final bool wasIceSockActive = current.isIceSockActive;
    final bool wasWaterDouseActive = current.isWaterDouseActive;

    // Jeśli w tym samym kroku aktywowano Ice Sock, nie odejmujemy dt z jego świeżego timera.
    final double nextIceSockSec = didActivateIceSock
        ? current.iceSockRemainingSeconds
        : math.max(0.0, current.iceSockRemainingSeconds - dt);
    final double nextWaterDouseSec =
        math.max(0.0, current.waterDouseRemainingSeconds - dt);

    final bool didExpireIceSock = wasIceSockActive && nextIceSockSec <= 0.0;
    final bool didExpireWaterDouse =
        wasWaterDouseActive && nextWaterDouseSec <= 0.0;

    // Po wygaśnięciu 15-minutowego efektu temperatura powoli wraca bez sztucznego skoku;
    // zewnętrzne chłodzenie spada do 0 W, a pełna dynamika termiczna przejmuje kontrolę.
    if (didExpireIceSock && radioNote == null) {
      radioNote = 'Lód w woreczku stopniał po 15 minutach — chłodzenie wygasło.';
    } else if (didExpireWaterDouse && radioNote == null) {
      radioNote = 'Woda z polewania głowy odparowała — efekt chłodzenia wygasł.';
    }

    current = current.copyWith(
      iceSockRemainingSeconds: nextIceSockSec,
      waterDouseRemainingSeconds: nextWaterDouseSec,
    );

    return CoolingStepResult(
      updatedState: current,
      externalCoolingWatts: _computeExternalCoolingWatts(current),
      stepCoolingDropCelsius: stepCoolingDrop,
      didActivateIceSock: didActivateIceSock,
      didExpireIceSock: didExpireIceSock,
      didExpireWaterDouse: didExpireWaterDouse,
      radioNotificationPl: radioNote,
    );
  }

  /// Wylicza rekomendowaną akcję chłodzącą na podstawie temperatury głębokiej i zasobów.
  static CoolingActionType? recommendCoolingAction(
    RiderHeatCoolingState state,
  ) {
    final bool isHot =
        state.ambientTemperatureCelsius >= heatAdvisoryAmbientCelsius ||
            state.coreBodyTemperatureCelsius >= recommendedCoolingCoreTempCelsius;
    if (!isHot) return null;

    if (state.canOrderIceSock && !state.isIceSockActive) {
      return CoolingActionType.iceSock;
    }
    if (state.canDouseWater && !state.isWaterDouseActive) {
      return CoolingActionType.waterDouse;
    }
    return null;
  }

  static double _computeExternalCoolingWatts(RiderHeatCoolingState state) {
    double watts = 0.0;
    if (state.isIceSockActive) {
      watts += iceSockCoolingPowerWatts;
    }
    if (state.isWaterDouseActive) {
      watts += waterDouseCoolingPowerWatts;
    }
    return watts;
  }
}

/// Produkcyjny panel taktyczny chłodzenia w upale (`Ice Sock` & `Water Douse`).
///
/// Zapewnia pełną responsywność (`390x844`, `1024x768`, `1600x900`), stany
/// `hover`/`active`/`disabled`/`focus` oraz spójność z paletą [AppColors] i fontem `Inter`.
class IceSocksAndWaterDousingPanel extends StatefulWidget {
  final RiderHeatCoolingState state;
  final ValueChanged<CoolingOrderOutcome>? onOrderExecuted;
  final String riderName;

  const IceSocksAndWaterDousingPanel({
    super.key,
    required this.state,
    this.onOrderExecuted,
    this.riderName = 'Lider zespołu',
  });

  @override
  State<IceSocksAndWaterDousingPanel> createState() =>
      _IceSocksAndWaterDousingPanelState();
}

class _IceSocksAndWaterDousingPanelState
    extends State<IceSocksAndWaterDousingPanel> {
  String? _lastRadioFeedback;
  bool _lastFeedbackError = false;

  void _handleIceSockPressed() {
    final outcome = IceSocksAndWaterDousingMechanics.orderIceSockFromTeamCar(
      widget.state,
      immediateDelivery: true,
    );
    setState(() {
      _lastRadioFeedback = outcome.radioMessagePl;
      _lastFeedbackError = !outcome.accepted;
    });
    widget.onOrderExecuted?.call(outcome);
  }

  void _handleWaterDousePressed() {
    final outcome =
        IceSocksAndWaterDousingMechanics.douseHeadWithWater(widget.state);
    setState(() {
      _lastRadioFeedback = outcome.radioMessagePl;
      _lastFeedbackError = !outcome.accepted;
    });
    widget.onOrderExecuted?.call(outcome);
  }

  String _formatRemainingTime(double seconds) {
    final int total = math.max(0, seconds.ceil());
    final int mins = total ~/ 60;
    final int secs = total % 60;
    final String mm = mins.toString().padLeft(2, '0');
    final String ss = secs.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  Color _temperatureColor(double coreTemp) {
    if (coreTemp >= 39.2) return AppColors.crimsonAlert;
    if (coreTemp >= 38.6) return AppColors.amberWarning;
    if (coreTemp >= 37.8) return AppColors.goldAccent;
    return AppColors.accentBlue;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 460;
        final double horizontalPadding = isCompact ? 14.0 : 20.0;
        final double coreTemp = widget.state.coreBodyTemperatureCelsius;
        final Color tempColor = _temperatureColor(coreTemp);
        final CoolingActionType? recommended =
            IceSocksAndWaterDousingMechanics.recommendCoolingAction(
          widget.state,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: isCompact ? 14.0 : 18.0,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.state.isCoolingActive
                  ? AppColors.accentBlue.withValues(alpha: 0.6)
                  : const Color(0xFF2A2F3D),
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(isCompact, coreTemp, tempColor),
              const SizedBox(height: 14),
              _buildTelemetryStrip(isCompact),
              const SizedBox(height: 14),
              if (isCompact) ...[
                _CoolingActionButton(
                  icon: Icons.ac_unit_rounded,
                  title: 'Ice Sock (Wóz)',
                  subtitle: widget.state.isIceSockActive
                      ? 'Aktywny: ${_formatRemainingTime(widget.state.iceSockRemainingSeconds)}'
                      : 'Zapas: ${widget.state.iceSocksAvailableInTeamCar} szt. • -0.4 °C / 15 min',
                  isActive: widget.state.isIceSockActive,
                  isRecommended: recommended == CoolingActionType.iceSock,
                  enabled: widget.state.canOrderIceSock,
                  accentColor: AppColors.accentBlue,
                  onPressed: _handleIceSockPressed,
                ),
                const SizedBox(height: 10),
                _CoolingActionButton(
                  icon: Icons.water_drop_rounded,
                  title: 'Polej głowę wodą',
                  subtitle: widget.state.isWaterDouseActive
                      ? 'Aktywny: ${_formatRemainingTime(widget.state.waterDouseRemainingSeconds)}'
                      : 'Bidony: ${widget.state.bidonsAvailable} szt. • -0.4 °C / 15 min',
                  isActive: widget.state.isWaterDouseActive,
                  isRecommended: recommended == CoolingActionType.waterDouse,
                  enabled: widget.state.canDouseWater,
                  accentColor: AppColors.cyanAccent,
                  onPressed: _handleWaterDousePressed,
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _CoolingActionButton(
                        icon: Icons.ac_unit_rounded,
                        title: 'Ice Sock (Wóz)',
                        subtitle: widget.state.isIceSockActive
                            ? 'Aktywny: ${_formatRemainingTime(widget.state.iceSockRemainingSeconds)}'
                            : 'Zapas: ${widget.state.iceSocksAvailableInTeamCar} szt. • -0.4 °C / 15 min',
                        isActive: widget.state.isIceSockActive,
                        isRecommended: recommended == CoolingActionType.iceSock,
                        enabled: widget.state.canOrderIceSock,
                        accentColor: AppColors.accentBlue,
                        onPressed: _handleIceSockPressed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CoolingActionButton(
                        icon: Icons.water_drop_rounded,
                        title: 'Polej głowę wodą',
                        subtitle: widget.state.isWaterDouseActive
                            ? 'Aktywny: ${_formatRemainingTime(widget.state.waterDouseRemainingSeconds)}'
                            : 'Bidony: ${widget.state.bidonsAvailable} szt. • -0.4 °C / 15 min',
                        isActive: widget.state.isWaterDouseActive,
                        isRecommended:
                            recommended == CoolingActionType.waterDouse,
                        enabled: widget.state.canDouseWater,
                        accentColor: AppColors.cyanAccent,
                        onPressed: _handleWaterDousePressed,
                      ),
                    ),
                  ],
                ),
              if (_lastRadioFeedback != null) ...[
                const SizedBox(height: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _lastFeedbackError
                        ? AppColors.crimsonAlert.withValues(alpha: 0.12)
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _lastFeedbackError
                          ? AppColors.crimsonAlert.withValues(alpha: 0.5)
                          : const Color(0xFF2A2F3D),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _lastFeedbackError
                            ? Icons.warning_amber_rounded
                            : Icons.headset_mic_rounded,
                        size: 16,
                        color: _lastFeedbackError
                            ? AppColors.crimsonAlert
                            : AppColors.goldAccent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastRadioFeedback!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact, double coreTemp, Color tempColor) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2A2F3D)),
          ),
          child: const Icon(
            Icons.thermostat_rounded,
            color: AppColors.accentBlue,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chłodzenie w upale • ${widget.riderName}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isCompact ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              Text(
                'Otoczenie ${widget.state.ambientTemperatureCelsius.toStringAsFixed(1)} °C',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: tempColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tempColor.withValues(alpha: 0.45)),
          ),
          child: Text(
            '${coreTemp.toStringAsFixed(1)} °C',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tempColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTelemetryStrip(bool isCompact) {
    final double reduction = widget.state.activeTemperatureReductionCelsius;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Wrap(
        spacing: isCompact ? 12 : 20,
        runSpacing: 6,
        alignment: WrapAlignment.spaceBetween,
        children: [
          _TelemetryChip(
            label: 'Efekt chłodzenia',
            value: reduction > 0.0
                ? '-${reduction.toStringAsFixed(2)} °C'
                : '0.00 °C',
            valueColor: reduction > 0.0
                ? AppColors.statusSuccess
                : AppColors.textSecondary,
          ),
          _TelemetryChip(
            label: 'Pozostało',
            value: widget.state.isCoolingActive
                ? _formatRemainingTime(widget.state.maxRemainingCoolingSeconds)
                : '--:--',
            valueColor: widget.state.isCoolingActive
                ? AppColors.accentBlue
                : AppColors.textSecondary,
          ),
          _TelemetryChip(
            label: 'Lód / Bidony',
            value:
                '${widget.state.iceSocksAvailableInTeamCar} / ${widget.state.bidonsAvailable}',
            valueColor: AppColors.textPrimary,
          ),
        ],
      ),
    );
  }
}

class _TelemetryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryChip({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _CoolingActionButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isRecommended;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _CoolingActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isRecommended,
    required this.enabled,
    required this.accentColor,
    required this.onPressed,
  });

  @override
  State<_CoolingActionButton> createState() => _CoolingActionButtonState();
}

class _CoolingActionButtonState extends State<_CoolingActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool effectiveEnabled = widget.enabled;
    final Color borderColor;
    if (!effectiveEnabled) {
      borderColor = const Color(0xFF2A2F3D);
    } else if (_isFocused) {
      borderColor = AppColors.goldAccent;
    } else if (widget.isActive || _isHovered) {
      borderColor = widget.accentColor;
    } else if (widget.isRecommended) {
      borderColor = AppColors.amberWarning.withValues(alpha: 0.7);
    } else {
      borderColor = const Color(0xFF2A2F3D);
    }

    final Color bgColor;
    if (!effectiveEnabled) {
      bgColor = AppColors.background.withValues(alpha: 0.6);
    } else if (_isPressed) {
      bgColor = widget.accentColor.withValues(alpha: 0.22);
    } else if (_isHovered || widget.isActive) {
      bgColor = widget.accentColor.withValues(alpha: 0.14);
    } else {
      bgColor = AppColors.surfaceLight;
    }

    return FocusableActionDetector(
      enabled: effectiveEnabled,
      onShowFocusHighlight: (focused) {
        setState(() => _isFocused = focused);
      },
      onShowHoverHighlight: (hovered) {
        setState(() => _isHovered = hovered);
      },
      mouseCursor: effectiveEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: effectiveEnabled
            ? (_) => setState(() => _isPressed = true)
            : null,
        onTapUp: effectiveEnabled
            ? (_) => setState(() => _isPressed = false)
            : null,
        onTapCancel: effectiveEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: effectiveEnabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: _isFocused ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: effectiveEnabled
                    ? widget.accentColor
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: effectiveEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.6),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: effectiveEnabled
                            ? AppColors.textSecondary
                            : AppColors.textSecondary.withValues(alpha: 0.45),
                        letterSpacing: -0.2,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
