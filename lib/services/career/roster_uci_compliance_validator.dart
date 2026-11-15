// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import '../../models/equipment/complete_bike.dart';
import '../../models/equipment/equipment_wear_and_maintenance.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import 'anti_doping_and_whereabouts_service.dart';

/// Kategoria naruszenia przepisów UCI podczas weryfikacji składu wyścigowego.
enum RosterComplianceViolationType {
  /// Liczba kolarzy przekracza regulaminowy limit UCI dla danego wyścigu.
  rosterSizeExceeded,

  /// Skład ma mniej kolarzy niż wymagana liczba startowa.
  rosterSizeInsufficient,

  /// Kolarz posiada aktywną kontuzję, chorobę lub zawieszenie medyczne.
  medicalSuspension,

  /// Kolarz jest objęty aktywną sankcją antydopingową lub zawieszeniem ABP.
  dopingSuspension,

  /// Masa roweru nie spełnia regulaminowego minimum UCI (>= 6.80 kg).
  bikeUnderweight,

  /// Rower nie jest sprawny technicznie (zużyty łańcuch, opony, hamulce lub bateria Di2/AXS).
  bikeUnroadworthy,

  /// Kolarz nie ma przypisanego żadnego sprawnego roweru spełniającego wymogi UCI.
  missingCompliantBike,

  /// Ten sam kolarz został zgłoszony na liście startowej więcej niż raz.
  duplicateRider;

  String get displayName {
    switch (this) {
      case RosterComplianceViolationType.rosterSizeExceeded:
        return 'Przekroczony limit kolarzy UCI';
      case RosterComplianceViolationType.rosterSizeInsufficient:
        return 'Niepełny skład startowy';
      case RosterComplianceViolationType.medicalSuspension:
        return 'Zawieszenie medyczne / Kontuzja';
      case RosterComplianceViolationType.dopingSuspension:
        return 'Zawieszenie antydopingowe UCI/WADA';
      case RosterComplianceViolationType.bikeUnderweight:
        return 'Rower poniżej limitu 6.80 kg UCI';
      case RosterComplianceViolationType.bikeUnroadworthy:
        return 'Usterka techniczna roweru';
      case RosterComplianceViolationType.missingCompliantBike:
        return 'Brak sprawnego roweru UCI';
      case RosterComplianceViolationType.duplicateRider:
        return 'Zduplikowany kolarz na liście';
    }
  }
}

/// Pojedyncze naruszenie lub ostrzeżenie wykryte przez komisję techniczną UCI.
class RosterComplianceViolation {
  final RosterComplianceViolationType type;
  final String message;
  final String? riderId;
  final String? riderName;
  final String? bikeId;
  final bool isBlocking;

  const RosterComplianceViolation({
    required this.type,
    required this.message,
    this.riderId,
    this.riderName,
    this.bikeId,
    this.isBlocking = true,
  });

  @override
  String toString() =>
      '[${type.name}]${riderName != null ? ' $riderName:' : ''} $message';
}

/// Wynik kontroli technicznej pojedynczego roweru przed startem wyścigu UCI.
class BikeComplianceCheckResult {
  final CompleteBike bike;
  final double measuredWeightKg;
  final bool meetsMinimumWeight;
  final bool requiresBallast;
  final int ballastGramsNeeded;
  final bool isMechanicallyRoadworthy;
  final List<String> mechanicalDefects;

  const BikeComplianceCheckResult({
    required this.bike,
    required this.measuredWeightKg,
    required this.meetsMinimumWeight,
    required this.requiresBallast,
    required this.ballastGramsNeeded,
    required this.isMechanicallyRoadworthy,
    required this.mechanicalDefects,
  });

  bool get isCompliant => meetsMinimumWeight && isMechanicallyRoadworthy;
}

/// Zapis pojedynczej automatycznej korekty wykonanej podczas uzupełniania luk rezerwami.
class RosterAutoFillAction {
  final Rider addedReserve;
  final Rider? replacedRider;
  final CompleteBike? assignedBike;
  final String reason;

  const RosterAutoFillAction({
    required this.addedReserve,
    this.replacedRider,
    this.assignedBike,
    required this.reason,
  });
}

/// Kompletny raport z walidacji przepisów UCI oraz opcjonalnego auto-uzupełnienia składu.
class RosterUciComplianceReport {
  final String raceId;
  final String raceName;
  final int requiredRosterSize;
  final int initialRosterSize;
  final bool isInitiallyCompliant;
  final bool isResolvedCompliant;
  final List<RosterComplianceViolation> initialViolations;
  final List<RosterComplianceViolation> remainingViolations;
  final List<Rider> resolvedRoster;
  final Map<String, CompleteBike> resolvedBikesByRiderId;
  final List<RosterAutoFillAction> autoFillActions;
  final List<BikeComplianceCheckResult> bikeChecks;

  const RosterUciComplianceReport({
    required this.raceId,
    required this.raceName,
    required this.requiredRosterSize,
    required this.initialRosterSize,
    required this.isInitiallyCompliant,
    required this.isResolvedCompliant,
    required this.initialViolations,
    required this.remainingViolations,
    required this.resolvedRoster,
    required this.resolvedBikesByRiderId,
    required this.autoFillActions,
    required this.bikeChecks,
  });

  int get removedCount => autoFillActions
      .where((a) => a.replacedRider != null)
      .length;

  int get addedReservesCount => autoFillActions.length;
}

/// Walidator przepisów UCI dla składów wyścigowych i sprzętu drużyny.
///
/// Weryfikuje:
/// 1. Limit liczby kolarzy (8 na Grand Tour, 7 na wyścigi 1-dniowe / etapówki).
/// 2. Brak aktywnych zawieszeń medycznych (kontuzja, choroba, protokół wstrząśnienia).
/// 3. Brak aktywnych zawieszeń antydopingowych (sankcje WADA/UCI oraz paszport ABP).
/// 4. Sprawność techniczną i limit masy rowerów (>= 6.80 kg UCI).
/// 5. Automatyczne uzupełnianie luk zdrowymi, uprawnionymi rezerwami.
class RosterUciComplianceValidator {
  static const int uciGrandTourRosterSize = 8;
  static const int uciOneDayRosterSize = 7;
  static const double uciMinimumBikeWeightKg =
      CompleteBike.uciMinimumWeightLimitKg;
  static const double minimumElectronicBatteryPercent = 15.0;

  const RosterUciComplianceValidator();

  /// Zwraca regulaminową liczbę kolarzy w drużynie dla danego wyścigu UCI.
  int requiredRosterSizeForRace(TourRace race) {
    if (race.isGrandTour) {
      return uciGrandTourRosterSize;
    }
    if (race.isOneDayRace) {
      return uciOneDayRosterSize;
    }
    return race.ridersPerTeam > 0 ? race.ridersPerTeam : uciOneDayRosterSize;
  }

  /// Sprawdza pojedynczy rower pod kątem limitu masy >= 6.80 kg oraz sprawności mechanicznej.
  ///
  /// Jeśli [allowUciBallast] ma wartość `false` (domyślnie dla ścisłej kontroli wagi fizycznej),
  /// rower o `rawWeightKg < 6.80` bez zewnętrznej wagi doważonej zostaje odrzucony.
  /// Gdy [allowUciBallast] ma wartość `true`, rower lżejszy niż 6.80 kg przechodzi kontrolę
  /// po doliczeniu regulaminowego balastu UCI (`ballastGrams`).
  BikeComplianceCheckResult checkBikeCompliance(
    CompleteBike bike, {
    double? measuredWeightOverrideKg,
    bool allowUciBallast = false,
  }) {
    final effectiveRawWeight = measuredWeightOverrideKg ?? bike.rawWeightKg;
    final needsBallast = effectiveRawWeight < uciMinimumWeightOrConstant();
    final ballastGrams = needsBallast
        ? ((uciMinimumBikeWeightKg - effectiveRawWeight) * 1000.0).round()
        : 0;

    final meetsWeight = allowUciBallast
        ? (measuredWeightOverrideKg != null
            ? measuredWeightOverrideKg >= uciMinimumBikeWeightKg
            : bike.totalWeightKg >= uciMinimumBikeWeightKg)
        : effectiveRawWeight >= uciMinimumBikeWeightKg;

    final defects = _collectMechanicalDefects(bike.wear);

    return BikeComplianceCheckResult(
      bike: bike,
      measuredWeightKg:
          allowUciBallast && measuredWeightOverrideKg == null
              ? bike.totalWeightKg
              : effectiveRawWeight,
      meetsMinimumWeight: meetsWeight,
      requiresBallast: needsBallast,
      ballastGramsNeeded: ballastGrams,
      isMechanicallyRoadworthy: defects.isEmpty,
      mechanicalDefects: List<String>.unmodifiable(defects),
    );
  }

  double uciMinimumWeightOrConstant() => uciMinimumBikeWeightKg;

  List<String> _collectMechanicalDefects(EquipmentWearAndMaintenance wear) {
    final defects = <String>[];

    if (wear.chain.needsReplacement) {
      defects.add(
        'Rozciągnięty łańcuch (${wear.chain.chainElongationPercent.toStringAsFixed(2)}% >= 0.50%)',
      );
    }
    if (wear.chain.isWashedOut || wear.chain.waxFilmRemainingPercent <= 0.0) {
      defects.add('Wypłukany smar/wosk łańcucha (ryzyko zerwania napędu)');
    }
    if (wear.frontTire.needsReplacement) {
      defects.add(
        'Zużyta lub uszkodzona przednia opona (zużycie ${wear.frontTire.treadWearPercent.toStringAsFixed(0)}%, nacięcia: ${wear.frontTire.microCutsCount})',
      );
    }
    if (wear.rearTire.needsReplacement) {
      defects.add(
        'Zużyta lub uszkodzona tylna opona (zużycie ${wear.rearTire.treadWearPercent.toStringAsFixed(0)}%, nacięcia: ${wear.rearTire.microCutsCount})',
      );
    }
    if (wear.frontBrake.needsPadReplacement ||
        wear.frontBrake.needsRotorReplacement) {
      defects.add('Niesprawny przedni układ hamulcowy');
    }
    if (wear.rearBrake.needsPadReplacement ||
        wear.rearBrake.needsRotorReplacement) {
      defects.add('Niesprawny tylny układ hamulcowy');
    }
    if (wear.electronicBatteryPercent < minimumElectronicBatteryPercent) {
      defects.add(
        'Krytycznie niski poziom baterii Di2/AXS (${wear.electronicBatteryPercent.toStringAsFixed(0)}%)',
      );
    }

    return defects;
  }

  /// Sprawdza, czy kolarz ma aktywne zawieszenie medyczne na dzień wyścigu.
  String? getMedicalSuspensionReason(
    Rider rider, {
    Set<String> medicallySuspendedRiderIds = const {},
    Map<String, String> medicalSuspensionReasons = const {},
  }) {
    if (medicallySuspendedRiderIds.contains(rider.id)) {
      return medicalSuspensionReasons[rider.id] ??
          'Aktywna blokada medyczna sztabu/UCI';
    }
    if (rider.health.currentIllness != null &&
        rider.health.currentIllness!.trim().isNotEmpty) {
      return 'Choroba: ${rider.health.currentIllness}';
    }
    final injury = rider.health.currentInjury;
    if (injury != null && injury.daysRemaining > 0) {
      return 'Kontuzja: ${injury.name} (${injury.daysRemaining} dni do powrotu)';
    }
    if (!rider.health.isFitToRace) {
      return 'Kolarz niedopuszczony do startu przez lekarza wyścigu';
    }
    return null;
  }

  /// Sprawdza, czy kolarz jest objęty aktywną sankcją antydopingową lub zawieszeniem ABP.
  String? getDopingSuspensionReason(
    Rider rider, {
    required DateTime raceDate,
    List<AntiDopingSanction> activeSanctions = const [],
    Map<String, BiologicalPassportStatus> biologicalPassportStatuses = const {},
  }) {
    for (final sanction in activeSanctions) {
      if (sanction.riderId == rider.id &&
          _isSanctionActiveOnDate(sanction, raceDate)) {
        return 'Sankcja WADA/UCI do ${_formatIsoDate(sanction.endDate)}: ${sanction.reason}';
      }
    }

    final abpStatus = biologicalPassportStatuses[rider.id];
    if (abpStatus == BiologicalPassportStatus.suspended ||
        abpStatus == BiologicalPassportStatus.disciplinaryProceedings) {
      return 'Paszport Biologiczny (ABP): ${abpStatus!.displayName}';
    }

    return null;
  }

  bool _isSanctionActiveOnDate(AntiDopingSanction sanction, DateTime date) {
    return sanction.isActiveAt(date) ||
        date.isAtSameMomentAs(sanction.startDate);
  }

  String _formatIsoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Przeprowadza pełną walidację UCI zgłoszonego składu i automatycznie uzupełnia luki
  /// zdrowymi, niezwieszonymi rezerwami posiadającymi sprawne rowery (>= 6.80 kg).
  RosterUciComplianceReport validateAndAutoFill({
    required TourRace race,
    required List<Rider> selectedRoster,
    List<Rider> reservePool = const [],
    DateTime? raceDate,
    List<AntiDopingSanction> activeSanctions = const [],
    Map<String, BiologicalPassportStatus> biologicalPassportStatuses = const {},
    Set<String> medicallySuspendedRiderIds = const {},
    Map<String, String> medicalSuspensionReasons = const {},
    Map<String, CompleteBike>? assignedBikesByRiderId,
    List<CompleteBike> spareBikes = const [],
    Map<String, double> measuredBikeWeightsKg = const {},
    bool allowUciBallast = false,
    bool autoFillGaps = true,
  }) {
    final effectiveDate = raceDate ?? race.startDate;
    final requiredSize = requiredRosterSizeForRace(race);
    final initialViolations = <RosterComplianceViolation>[];
    final bikeChecks = <BikeComplianceCheckResult>[];

    // 1. Walidacja rozmiaru początkowego
    if (selectedRoster.length > requiredSize) {
      initialViolations.add(
        RosterComplianceViolation(
          type: RosterComplianceViolationType.rosterSizeExceeded,
          message:
              'Zgłoszono ${selectedRoster.length} kolarzy, limit UCI dla "${race.name}" wynosi $requiredSize.',
        ),
      );
    } else if (selectedRoster.length < requiredSize) {
      initialViolations.add(
        RosterComplianceViolation(
          type: RosterComplianceViolationType.rosterSizeInsufficient,
          message:
              'Zgłoszono ${selectedRoster.length} kolarzy, wymagane jest $requiredSize dla "${race.name}".',
        ),
      );
    }

    // 2. Inspekcja zgłoszonych kolarzy i ich rowerów
    final seenIds = <String>{};
    final validStarters = <Rider>[];
    final removedStarters = <_RemovedStarter>[];
    final resolvedBikes = <String, CompleteBike>{};
    final usedBikeIds = <String>{};

    // Przygotowanie puli zapasowych rowerów spełniających normę UCI
    final compliantSpareQueue = <CompleteBike>[];
    if (assignedBikesByRiderId != null || spareBikes.isNotEmpty) {
      for (final spare in spareBikes) {
        final check = checkBikeCompliance(
          spare,
          measuredWeightOverrideKg: measuredBikeWeightsKg[spare.id],
          allowUciBallast: allowUciBallast,
        );
        bikeChecks.add(check);
        if (check.isCompliant) {
          compliantSpareQueue.add(spare);
        }
      }
    }

    final checkBikesEnabled =
        assignedBikesByRiderId != null || spareBikes.isNotEmpty;

    for (final rider in selectedRoster) {
      if (!seenIds.add(rider.id)) {
        initialViolations.add(
          RosterComplianceViolation(
            type: RosterComplianceViolationType.duplicateRider,
            riderId: rider.id,
            riderName: rider.fullName,
            message: 'Kolarz ${rider.fullName} został wpisany na listę wielokrotnie.',
          ),
        );
        continue;
      }

      final dopingReason = getDopingSuspensionReason(
        rider,
        raceDate: effectiveDate,
        activeSanctions: activeSanctions,
        biologicalPassportStatuses: biologicalPassportStatuses,
      );
      if (dopingReason != null) {
        initialViolations.add(
          RosterComplianceViolation(
            type: RosterComplianceViolationType.dopingSuspension,
            riderId: rider.id,
            riderName: rider.fullName,
            message: dopingReason,
          ),
        );
        removedStarters.add(_RemovedStarter(rider: rider, reason: dopingReason));
        continue;
      }

      final medicalReason = getMedicalSuspensionReason(
        rider,
        medicallySuspendedRiderIds: medicallySuspendedRiderIds,
        medicalSuspensionReasons: medicalSuspensionReasons,
      );
      if (medicalReason != null) {
        initialViolations.add(
          RosterComplianceViolation(
            type: RosterComplianceViolationType.medicalSuspension,
            riderId: rider.id,
            riderName: rider.fullName,
            message: medicalReason,
          ),
        );
        removedStarters.add(_RemovedStarter(rider: rider, reason: medicalReason));
        continue;
      }

      if (checkBikesEnabled) {
        final assignedBike = assignedBikesByRiderId?[rider.id];
        CompleteBike? compliantBike;

        if (assignedBike != null) {
          final check = checkBikeCompliance(
            assignedBike,
            measuredWeightOverrideKg: measuredBikeWeightsKg[assignedBike.id],
            allowUciBallast: allowUciBallast,
          );
          bikeChecks.add(check);

          if (!check.meetsMinimumWeight) {
            initialViolations.add(
              RosterComplianceViolation(
                type: RosterComplianceViolationType.bikeUnderweight,
                riderId: rider.id,
                riderName: rider.fullName,
                bikeId: assignedBike.id,
                message:
                    'Rower "${assignedBike.name}" (${check.measuredWeightKg.toStringAsFixed(2)} kg) nie osiąga limitu UCI 6.80 kg.',
              ),
            );
          }
          if (!check.isMechanicallyRoadworthy) {
            initialViolations.add(
              RosterComplianceViolation(
                type: RosterComplianceViolationType.bikeUnroadworthy,
                riderId: rider.id,
                riderName: rider.fullName,
                bikeId: assignedBike.id,
                message:
                    'Rower "${assignedBike.name}" niesprawny: ${check.mechanicalDefects.join(', ')}.',
              ),
            );
          }

          if (check.isCompliant && !usedBikeIds.contains(assignedBike.id)) {
            compliantBike = assignedBike;
            usedBikeIds.add(assignedBike.id);
          }
        } else {
          initialViolations.add(
            RosterComplianceViolation(
              type: RosterComplianceViolationType.missingCompliantBike,
              riderId: rider.id,
              riderName: rider.fullName,
              message: 'Kolarz ${rider.fullName} nie ma przypisanego roweru wyścigowego.',
            ),
          );
        }

        // Jeśli przypisany rower zawiódł kontrolę, spróbuj przydzielić sprawny rower rezerwowy
        if (compliantBike == null) {
          final spareIdx = compliantSpareQueue
              .indexWhere((b) => !usedBikeIds.contains(b.id));
          if (spareIdx != -1) {
            compliantBike = compliantSpareQueue[spareIdx];
            usedBikeIds.add(compliantBike.id);
          }
        }

        if (compliantBike == null) {
          removedStarters.add(
            _RemovedStarter(
              rider: rider,
              reason: 'Brak sprawnego roweru spełniającego wymogi UCI (>= 6.80 kg)',
            ),
          );
          continue;
        }

        resolvedBikes[rider.id] = compliantBike;
      }

      validStarters.add(rider);
    }

    // Przycięcie nadmiarowych kolarzy ponad limit UCI
    if (validStarters.length > requiredSize) {
      validStarters.removeRange(requiredSize, validStarters.length);
    }

    // 3. Automatyczne uzupełnianie luk zdrowymi rezerwami
    final autoFillActions = <RosterAutoFillAction>[];
    final remainingViolations = <RosterComplianceViolation>[];

    if (autoFillGaps && validStarters.length < requiredSize) {
      final eligibleReserves = _findEligibleReserves(
        reservePool: reservePool,
        alreadySelectedIds: seenIds,
        raceDate: effectiveDate,
        activeSanctions: activeSanctions,
        biologicalPassportStatuses: biologicalPassportStatuses,
        medicallySuspendedRiderIds: medicallySuspendedRiderIds,
        medicalSuspensionReasons: medicalSuspensionReasons,
      );

      int removedCursor = 0;
      for (final reserve in eligibleReserves) {
        if (validStarters.length >= requiredSize) break;

        CompleteBike? reserveBike;
        if (checkBikesEnabled) {
          final assigned = assignedBikesByRiderId?[reserve.id];
          if (assigned != null && !usedBikeIds.contains(assigned.id)) {
            final check = checkBikeCompliance(
              assigned,
              measuredWeightOverrideKg: measuredBikeWeightsKg[assigned.id],
              allowUciBallast: allowUciBallast,
            );
            bikeChecks.add(check);
            if (check.isCompliant) {
              reserveBike = assigned;
            }
          }
          if (reserveBike == null) {
            final spareIdx = compliantSpareQueue
                .indexWhere((b) => !usedBikeIds.contains(b.id));
            if (spareIdx != -1) {
              reserveBike = compliantSpareQueue[spareIdx];
            }
          }
          if (reserveBike == null) {
            continue;
          }
          usedBikeIds.add(reserveBike.id);
          resolvedBikes[reserve.id] = reserveBike;
        }

        final replaced = removedCursor < removedStarters.length
            ? removedStarters[removedCursor++]
            : null;

        validStarters.add(reserve);
        seenIds.add(reserve.id);
        autoFillActions.add(
          RosterAutoFillAction(
            addedReserve: reserve,
            replacedRider: replaced?.rider,
            assignedBike: reserveBike,
            reason: replaced != null
                ? 'Zastępstwo za ${replaced.rider.fullName} (${replaced.reason})'
                : 'Uzupełnienie wolnego miejsca w limicie $requiredSize kolarzy',
          ),
        );
      }
    }

    if (validStarters.length < requiredSize) {
      remainingViolations.add(
        RosterComplianceViolation(
          type: RosterComplianceViolationType.rosterSizeInsufficient,
          message:
              'Po walidacji i uzupełnieniu dostępnych rezerw skład liczy ${validStarters.length}/$requiredSize kolarzy.',
        ),
      );
    }

    return RosterUciComplianceReport(
      raceId: race.id,
      raceName: race.name,
      requiredRosterSize: requiredSize,
      initialRosterSize: selectedRoster.length,
      isInitiallyCompliant: initialViolations.isEmpty,
      isResolvedCompliant: remainingViolations.isEmpty &&
          validStarters.length == requiredSize,
      initialViolations: List<RosterComplianceViolation>.unmodifiable(
        initialViolations,
      ),
      remainingViolations: List<RosterComplianceViolation>.unmodifiable(
        remainingViolations,
      ),
      resolvedRoster: List<Rider>.unmodifiable(validStarters),
      resolvedBikesByRiderId: Map<String, CompleteBike>.unmodifiable(
        resolvedBikes,
      ),
      autoFillActions: List<RosterAutoFillAction>.unmodifiable(autoFillActions),
      bikeChecks: List<BikeComplianceCheckResult>.unmodifiable(bikeChecks),
    );
  }

  List<Rider> _findEligibleReserves({
    required List<Rider> reservePool,
    required Set<String> alreadySelectedIds,
    required DateTime raceDate,
    required List<AntiDopingSanction> activeSanctions,
    required Map<String, BiologicalPassportStatus> biologicalPassportStatuses,
    required Set<String> medicallySuspendedRiderIds,
    required Map<String, String> medicalSuspensionReasons,
  }) {
    final eligible = <Rider>[];

    for (final candidate in reservePool) {
      if (alreadySelectedIds.contains(candidate.id)) continue;

      final dopingReason = getDopingSuspensionReason(
        candidate,
        raceDate: raceDate,
        activeSanctions: activeSanctions,
        biologicalPassportStatuses: biologicalPassportStatuses,
      );
      if (dopingReason != null) continue;

      final medicalReason = getMedicalSuspensionReason(
        candidate,
        medicallySuspendedRiderIds: medicallySuspendedRiderIds,
        medicalSuspensionReasons: medicalSuspensionReasons,
      );
      if (medicalReason != null) continue;

      eligible.add(candidate);
    }

    // Sortowanie rezerw: najwyższy OVR, a przy remisie lepsza świeżość TSB
    eligible.sort((a, b) {
      final ovrCompare = b.overallRating.compareTo(a.overallRating);
      if (ovrCompare != 0) return ovrCompare;
      return b.health.trainingStressBalance
          .compareTo(a.health.trainingStressBalance);
    });

    return eligible;
  }
}

class _RemovedStarter {
  final Rider rider;
  final String reason;

  const _RemovedStarter({
    required this.rider,
    required this.reason,
  });
}
