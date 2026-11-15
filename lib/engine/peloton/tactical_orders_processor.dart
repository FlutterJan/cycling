import 'dart:math' as math;
import '../../core/constants/physics_constants.dart';
import '../../models/rider/rider_physiology.dart';
import '../../models/rider/rider_skills.dart';
import 'drafting_grid_system.dart';
import 'rider_race_state.dart';

/// Faza operacji zjazdu po bidony do wozu technicznego.
enum BidonFetchPhase {
  /// Brak aktywnej operacji zjazdu po bidony
  none,

  /// Kolarz spływa przez peleton na tył kolumny samochodów
  droppingToCar,

  /// Kolarz jedzie przy oknie wozu technicznego, pobierając bidony i batony
  atCar,

  /// Kolarz przedziera się przez kolumnę aut i goni peleton ("za wozami")
  chasingBack,

  /// Kolarz dotarł do kolegów i rozdaje bidony
  distributing;

  String toJson() => name;

  static BidonFetchPhase fromJson(String value) {
    return BidonFetchPhase.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => BidonFetchPhase.none,
    );
  }
}

/// Śledzenie postępu misji zjazdu po bidony do wozu technicznego.
class BidonFetchProgress {
  final BidonFetchPhase phase;
  final double timeInPhaseSeconds;
  final int bidonsCarried;

  const BidonFetchProgress({
    this.phase = BidonFetchPhase.none,
    this.timeInPhaseSeconds = 0.0,
    this.bidonsCarried = 0,
  });

  bool get isActive => phase != BidonFetchPhase.none;

  BidonFetchProgress copyWith({
    BidonFetchPhase? phase,
    double? timeInPhaseSeconds,
    int? bidonsCarried,
  }) {
    return BidonFetchProgress(
      phase: phase ?? this.phase,
      timeInPhaseSeconds: timeInPhaseSeconds ?? this.timeInPhaseSeconds,
      bidonsCarried: bidonsCarried ?? this.bidonsCarried,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': phase.toJson(),
      'timeInPhaseSeconds': timeInPhaseSeconds,
      'bidonsCarried': bidonsCarried,
    };
  }

  factory BidonFetchProgress.fromJson(Map<String, dynamic> json) {
    return BidonFetchProgress(
      phase: BidonFetchPhase.fromJson(json['phase'] as String),
      timeInPhaseSeconds: (json['timeInPhaseSeconds'] as num).toDouble(),
      bidonsCarried: (json['bidonsCarried'] as num).toInt(),
    );
  }
}

/// Wynik przetworzenia rozkazu taktycznego w danej sekundzie wyścigu.
class TacticalOrderResult {
  /// Docelowa moc wyjściowa, jaką kolarz ma wygenerować na korbie [W]
  final int targetWatts;

  /// Zaktualizowany stan kolarza [RiderRaceState]
  final RiderRaceState updatedState;

  /// Postęp zadania zjazdu po bidony
  final BidonFetchProgress fetchProgress;

  /// Dodatkowy modyfikator oszczędności aerodynamicznej (np. osłona lidera)
  final double draftingModifier;

  /// Czy zadanie zjazdu po bidony zostało pomyślnie ukończone w tej sekundzie
  final bool didCompleteBidonDelivery;

  /// Komunikat radiowy dyrektora sportowego / telemetryczny opis akcji
  final String? radioMessage;

  const TacticalOrderResult({
    required this.targetWatts,
    required this.updatedState,
    required this.fetchProgress,
    this.draftingModifier = 0.0,
    this.didCompleteBidonDelivery = false,
    this.radioMessage,
  });

  @override
  String toString() {
    return 'TacticalOrderResult(target: ${targetWatts}W, order: ${updatedState.activeTacticalOrder.name}, '
        'phase: ${fetchProgress.phase.name}, delivered: $didCompleteBidonDelivery)';
  }
}

/// Procesor rozkazów taktycznych dyrektora sportowego.
///
/// Przetwarza rozkaz gracza/AI na docelową moc wyjściową ([targetWatts])
/// oraz koordynuje złożone zachowania peletonowe:
/// - `ProtectLeader`: utrzymywanie pozycji tuż przed liderem, tnąc wiatr i osłaniając go.
/// - `FetchBidonsFromCar`: wielofazowy zjazd na tył kolumny, pobranie bidonów i pogoń z powrotem.
/// - `PullGroup`: wychodzenie na pierwszą linię z zadaną intensywnością (% FTP).
/// - `Attack`: gwałtowny beztlenowy zryw z grupy.
/// - `FollowWheels`: sklejanie koła i reakcja na przyspieszenia rywali.
/// - `SaveEnergy`: głębokie chowanie się w peletonie przy minimalnej mocy.
/// - `HoldPosition`: jazda w tempie grupy z aktualnym draftingiem.
class TacticalOrdersProcessor {
  TacticalOrdersProcessor._();

  /// Szacuje moc w watach wymaganą do utrzymania zadanej prędkości [speedMs] w grupie.
  static double estimatePowerForSpeed({
    required double speedMs,
    required double riderMassKg,
    required double gradientPercent,
    required double draftingReduction,
    double effectiveCdA = 0.320,
    double effectiveCrr = 0.0040,
    double drivetrainLoss = PhysicsConstants.drivetrainLossStandard,
  }) {
    if (speedMs <= 0.5) return 20.0;

    final double totalMass = riderMassKg + 8.5; // Kolarz + rower + bidony
    final double gFraction = gradientPercent / 100.0;
    final double slopeRad = math.atan(gFraction);

    final double fGravity = totalMass * PhysicsConstants.gravity * math.sin(slopeRad);
    final double fRolling = totalMass * PhysicsConstants.gravity * math.cos(slopeRad) * effectiveCrr;

    final double clampedDrafting = draftingReduction.clamp(0.0, 0.48);
    final double netCdA = effectiveCdA * (1.0 - clampedDrafting);
    final double fAero = 0.5 * PhysicsConstants.seaLevelAirDensity * netCdA * speedMs * speedMs;

    final double fRoad = fGravity + fRolling + fAero;
    final double pRoad = fRoad * speedMs;

    if (pRoad <= 0.0) return 0.0;

    final double efficiency = 1.0 - drivetrainLoss.clamp(0.0, 0.15);
    return pRoad / efficiency;
  }

  /// Główna metoda przetwarzająca rozkaz taktyczny kolarza.
  ///
  /// Parametry:
  /// - [riderState]: bieżący stan kolarza ([RiderRaceState])
  /// - [physiology]: profil fizjologiczny kolarza ([RiderPhysiology])
  /// - [skills]: umiejętności techniczne kolarza ([RiderSkills])
  /// - [group]: grupa, w której jedzie kolarz ([PelotonGroup])
  /// - [currentGroupSpeedMs]: aktualna prędkość grupy w m/s
  /// - [roadGradientPercent]: nachylenie trasy w %
  /// - [pullIntensityPercent]: intensywność nadawania tempa przy [TacticalOrder.pullGroup] (np. 85%, 95%, 105% FTP)
  /// - [leaderRiderId]: identyfikator chronionego lidera (dla [TacticalOrder.protectLeader])
  /// - [targetRivalId]: identyfikator pilnowanego rywala (dla [TacticalOrder.followWheels])
  /// - [fetchProgress]: aktualny stan realizacji zjazdu po bidony
  /// - [timeStepSeconds]: krok czasowy symulacji (domyślnie 1.0 s)
  static TacticalOrderResult processOrder({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required RiderSkills skills,
    required PelotonGroup group,
    required double currentGroupSpeedMs,
    required double roadGradientPercent,
    double pullIntensityPercent = 95.0,
    String? leaderRiderId,
    String? targetRivalId,
    BidonFetchProgress fetchProgress = const BidonFetchProgress(),
    double timeStepSeconds = 1.0,
  }) {
    final double ftp = physiology.ftpWatts.toDouble();

    switch (riderState.activeTacticalOrder) {
      case TacticalOrder.protectLeader:
        return _processProtectLeader(
          riderState: riderState,
          physiology: physiology,
          skills: skills,
          group: group,
          currentGroupSpeedMs: currentGroupSpeedMs,
          roadGradientPercent: roadGradientPercent,
          leaderRiderId: leaderRiderId,
        );

      case TacticalOrder.fetchBidonsFromCar:
        return _processFetchBidons(
          riderState: riderState,
          physiology: physiology,
          currentGroupSpeedMs: currentGroupSpeedMs,
          roadGradientPercent: roadGradientPercent,
          progress: fetchProgress,
          timeStepSeconds: timeStepSeconds,
        );

      case TacticalOrder.pullGroup:
        return _processPullGroup(
          riderState: riderState,
          physiology: physiology,
          pullIntensityPercent: pullIntensityPercent,
        );

      case TacticalOrder.attack:
        return _processAttack(
          riderState: riderState,
          physiology: physiology,
          skills: skills,
        );

      case TacticalOrder.followWheels:
        return _processFollowWheels(
          riderState: riderState,
          physiology: physiology,
          skills: skills,
          currentGroupSpeedMs: currentGroupSpeedMs,
          roadGradientPercent: roadGradientPercent,
          targetRivalId: targetRivalId,
        );

      case TacticalOrder.saveEnergy:
        return _processSaveEnergy(
          riderState: riderState,
          physiology: physiology,
          skills: skills,
          currentGroupSpeedMs: currentGroupSpeedMs,
          roadGradientPercent: roadGradientPercent,
        );

      case TacticalOrder.holdPosition:
        return _processHoldPosition(
          riderState: riderState,
          physiology: physiology,
          skills: skills,
          group: group,
          currentGroupSpeedMs: currentGroupSpeedMs,
          roadGradientPercent: roadGradientPercent,
        );
    }
  }

  /// 1. `ProtectLeader`: Kolarz jedzie tuż przed liderem zespołu, biorąc na siebie opór powietrza.
  /// Pomocnik ma zredukowaną osłonę, natomiast lider zyskuje maksymalny drafting.
  static TacticalOrderResult _processProtectLeader({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required RiderSkills skills,
    required PelotonGroup group,
    required double currentGroupSpeedMs,
    required double roadGradientPercent,
    String? leaderRiderId,
  }) {
    // Pomocnik jedzie przed liderem, więc sam ma mniejszą osłonę (np. tylko 12% zamiast 38%)
    const double protectorDrafting = 0.12;

    final double requiredPower = estimatePowerForSpeed(
      speedMs: currentGroupSpeedMs,
      riderMassKg: physiology.weightKg,
      gradientPercent: roadGradientPercent,
      draftingReduction: protectorDrafting,
    );

    // Kolarz daje z siebie wszystko, by utrzymać pozycję przed liderem (do 105% FTP)
    final int targetWatts = requiredPower.round().clamp(100, (physiology.ftpWatts * 1.08).round());

    // Lider zespołu zyskuje potężną osłonę aerodynamiczną (bonus +15% do draftingu)
    return TacticalOrderResult(
      targetWatts: targetWatts,
      updatedState: riderState.copyWith(
        currentWatts: targetWatts,
      ),
      fetchProgress: const BidonFetchProgress(),
      draftingModifier: 0.15,
      radioMessage: leaderRiderId != null
          ? 'Osłaniam lidera [$leaderRiderId] na czele formacji.'
          : 'Trzymam pozycję ochronną przed liderem.',
    );
  }

  /// 2. `FetchBidonsFromCar`: Wielofazowa misja zjazdu po bidony i batony do wozu technicznego.
  static TacticalOrderResult _processFetchBidons({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required double currentGroupSpeedMs,
    required double roadGradientPercent,
    required BidonFetchProgress progress,
    required double timeStepSeconds,
  }) {
    final double ftp = physiology.ftpWatts.toDouble();
    BidonFetchPhase currentPhase = progress.phase;
    double timeInPhase = progress.timeInPhaseSeconds + timeStepSeconds;
    int bidonsCarried = progress.bidonsCarried;
    int targetWatts;
    bool completed = false;
    String? radioMsg;

    if (currentPhase == BidonFetchPhase.none) {
      currentPhase = BidonFetchPhase.droppingToCar;
      timeInPhase = 0.0;
    }

    switch (currentPhase) {
      case BidonFetchPhase.droppingToCar:
        // Faza 1: Kolarz odpuszcza pedałowanie i spływa na koniec peletonu (trwa ~25 sekund)
        targetWatts = (ftp * 0.45).round(); // Lekkie kręcenie
        radioMsg = 'Spływam przez peleton do kolumny wozów technicznych.';
        if (timeInPhase >= 25.0) {
          currentPhase = BidonFetchPhase.atCar;
          timeInPhase = 0.0;
        }
        break;

      case BidonFetchPhase.atCar:
        // Faza 2: Przy samochodzie dyrektora – pobranie 4 bidonów i żeli (trwa ~12 sekund)
        targetWatts = (ftp * 0.70).round(); // Jazda przy oknie ("sticky bottle")
        bidonsCarried = 4;
        radioMsg = 'Pobieram bidony z wozu technicznego.';
        if (timeInPhase >= 12.0) {
          currentPhase = BidonFetchPhase.chasingBack;
          timeInPhase = 0.0;
        }
        break;

      case BidonFetchPhase.chasingBack:
        // Faza 3: Pogoń za peletonem przez kolumnę aut (trwa ~45 sekund, wymaga 110-120% FTP!)
        targetWatts = (ftp * 1.15).round();
        radioMsg = 'Wracam za wozami z pełnym ładunkiem bidonów!';
        if (timeInPhase >= 45.0) {
          currentPhase = BidonFetchPhase.distributing;
          timeInPhase = 0.0;
        }
        break;

      case BidonFetchPhase.distributing:
        // Faza 4: Dotarcie do zespołu i rozdanie bidonów (trwa ~8 sekund)
        targetWatts = (ftp * 0.85).round();
        radioMsg = 'Bidony rozdane kolegom z drużyny!';
        if (timeInPhase >= 8.0) {
          completed = true;
          currentPhase = BidonFetchPhase.none;
        }
        break;

      case BidonFetchPhase.none:
        targetWatts = (ftp * 0.80).round();
        break;
    }

    // Jeśli ukończono dostawę, przywracamy kolarzowi pełne 2 bidony w koszykach
    final updatedState = riderState.copyWith(
      currentWatts: targetWatts,
      bidonsLeft: completed ? 2 : riderState.bidonsLeft,
      gelsLeft: completed ? math.min(6, riderState.gelsLeft + 2) : riderState.gelsLeft,
      activeTacticalOrder: completed ? TacticalOrder.holdPosition : TacticalOrder.fetchBidonsFromCar,
    );

    return TacticalOrderResult(
      targetWatts: targetWatts,
      updatedState: updatedState,
      fetchProgress: BidonFetchProgress(
        phase: currentPhase,
        timeInPhaseSeconds: timeInPhase,
        bidonsCarried: bidonsCarried,
      ),
      didCompleteBidonDelivery: completed,
      radioMessage: radioMsg,
    );
  }

  /// 3. `PullGroup`: Wyjście na pierwszą linię i dyktowanie tempa z zadaną intensywnością (% FTP).
  static TacticalOrderResult _processPullGroup({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required double pullIntensityPercent,
  }) {
    final double intensityFactor = (pullIntensityPercent / 100.0).clamp(0.70, 1.30);
    final int targetWatts = (physiology.ftpWatts * intensityFactor).round();

    return TacticalOrderResult(
      targetWatts: targetWatts,
      updatedState: riderState.copyWith(
        currentWatts: targetWatts,
      ),
      fetchProgress: const BidonFetchProgress(),
      draftingModifier: -0.30, // Kolarz na czele traci osłonę aerodynamiczną
      radioMessage: 'Prowadzę grupę z mocą ${targetWatts}W (${pullIntensityPercent.toStringAsFixed(0)}% FTP).',
    );
  }

  /// 4. `Attack`: Gwałtowne przyspieszenie beztlenowe (135% - 160% FTP).
  static TacticalOrderResult _processAttack({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required RiderSkills skills,
  }) {
    // Kolarze o wysokiej zrywności atakują z większą mocą szczytową
    final double attackFactor = 1.40 + ((skills.bikeHandling - 50) / 100.0) * 0.20;
    final int targetWatts = (physiology.ftpWatts * attackFactor).round().clamp(500, 1400);

    return TacticalOrderResult(
      targetWatts: targetWatts,
      updatedState: riderState.copyWith(
        currentWatts: targetWatts,
      ),
      fetchProgress: const BidonFetchProgress(),
      draftingModifier: -0.40, // Atakujący wychodzi z cienia peletonu na pełny wiatr
      radioMessage: 'Atakuję! Ogień na korby (${targetWatts}W)!',
    );
  }

  /// 5. `FollowWheels`: Pilnowanie koła rywala lub natychmiastowa reakcja na skok.
  static TacticalOrderResult _processFollowWheels({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required RiderSkills skills,
    required double currentGroupSpeedMs,
    required double roadGradientPercent,
    String? targetRivalId,
  }) {
    // Kolarz korzysta z solidnego draftingu za pilnowanym rywalem (~34%)
    final double drafting = 0.34 * skills.draftingBonusMultiplier;

    final double basePower = estimatePowerForSpeed(
      speedMs: currentGroupSpeedMs * 1.03, // Jedzie z lekkim nadmiarem, by nie zgubić koła
      riderMassKg: physiology.weightKg,
      gradientPercent: roadGradientPercent,
      draftingReduction: drafting,
    );

    final int targetWatts = basePower.round().clamp(120, (physiology.ftpWatts * 1.35).round());

    return TacticalOrderResult(
      targetWatts: targetWatts,
      updatedState: riderState.copyWith(
        currentWatts: targetWatts,
      ),
      fetchProgress: const BidonFetchProgress(),
      draftingModifier: 0.05,
      radioMessage: targetRivalId != null
          ? 'Sklejone koło rywala [$targetRivalId].'
          : 'Pilnuję koła, nie dam im odjechać.',
    );
  }

  /// 6. `SaveEnergy`: Maksymalne oszczędzanie sił w głębi peletonu.
  static TacticalOrderResult _processSaveEnergy({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required RiderSkills skills,
    required double currentGroupSpeedMs,
    required double roadGradientPercent,
  }) {
    // Maksymalny drafting w tunelu aero (do 44%)
    final double maxDrafting = 0.44 * skills.draftingBonusMultiplier;

    final double minRequiredPower = estimatePowerForSpeed(
      speedMs: currentGroupSpeedMs,
      riderMassKg: physiology.weightKg,
      gradientPercent: roadGradientPercent,
      draftingReduction: maxDrafting,
    );

    // Kolarz kręci tylko tyle, by utrzymać się w grupie (strefa Z1/Z2)
    final int targetWatts = math.max(60, minRequiredPower.round());

    return TacticalOrderResult(
      targetWatts: targetWatts,
      updatedState: riderState.copyWith(
        currentWatts: targetWatts,
      ),
      fetchProgress: const BidonFetchProgress(),
      draftingModifier: 0.10,
      radioMessage: 'Głęboko schowany w peletonie, oszczędzam siły (${targetWatts}W).',
    );
  }

  /// 7. `HoldPosition`: Domyślna, zrównoważona jazda w tempie grupy.
  static TacticalOrderResult _processHoldPosition({
    required RiderRaceState riderState,
    required RiderPhysiology physiology,
    required RiderSkills skills,
    required PelotonGroup group,
    required double currentGroupSpeedMs,
    required double roadGradientPercent,
  }) {
    // Pobranie indywidualnego draftingu z pozycji w siatce grupy
    final gridPos = group.getPositionForRider(riderState.riderId);
    final double drafting = gridPos != null
        ? gridPos.draftingReduction * skills.draftingBonusMultiplier
        : 0.32;

    final double requiredPower = estimatePowerForSpeed(
      speedMs: currentGroupSpeedMs,
      riderMassKg: physiology.weightKg,
      gradientPercent: roadGradientPercent,
      draftingReduction: drafting,
    );

    final int targetWatts = math.max(70, requiredPower.round());

    return TacticalOrderResult(
      targetWatts: targetWatts,
      updatedState: riderState.copyWith(
        currentWatts: targetWatts,
      ),
      fetchProgress: const BidonFetchProgress(),
      radioMessage: 'Trzymam pozycję w grupie.',
    );
  }
}

