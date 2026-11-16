// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';

/// Kategoria zdarzenia haptycznego w symulacji wyścigu i interfejsie.
enum HapticEventCategory {
  cobbleSectorRhythm('Bruk 5★ — Rytm'),
  crashImpact('Kraksa — Uderzenie'),
  wattBombAttack('Atak Watt Bomb'),
  gearShift('Zmiana przełożenia'),
  tacticalOrder('Rozkaz taktyczny');

  final String label;
  const HapticEventCategory(this.label);
}

/// Typ impulsu mapowany bezpośrednio na API [HapticFeedback] we Flutterze.
enum HapticPulseType {
  lightImpact('Light Impact'),
  mediumImpact('Medium Impact'),
  heavyImpact('Heavy Impact'),
  selectionClick('Selection Click'),
  vibrate('Vibrate');

  final String label;
  const HapticPulseType(this.label);
}

/// Poziom intensywności haptyki i wibracji.
enum HapticIntensityPreset {
  off('Wyłączona', 0.0),
  subtle('Subtelna', 0.50),
  balanced('Zbalansowana', 0.85),
  proTactile('Pełna Pro', 1.0);

  final String label;
  final double scale;
  const HapticIntensityPreset(this.label, this.scale);
}

/// Delegat wywołania natywnego impulsu haptycznego (umożliwia bezpieczny fallback i testy).
typedef HapticDispatchCallback = Future<void> Function(
  HapticPulseType pulseType,
);

/// Pojedynczy wpis telemetrii wyemitowanego impulsu haptycznego.
@immutable
class HapticVibrationEventRecord {
  final DateTime timestamp;
  final HapticEventCategory category;
  final HapticPulseType pulseType;
  final String description;
  final double intensity;
  final int sequenceIndex;
  final int totalInSequence;

  const HapticVibrationEventRecord({
    required this.timestamp,
    required this.category,
    required this.pulseType,
    required this.description,
    required this.intensity,
    this.sequenceIndex = 1,
    this.totalInSequence = 1,
  });
}

/// Niezmienny stan kontrolera haptyki i wibracji [HapticFeedbackVibrationController].
@immutable
class HapticVibrationState {
  final bool isEnabled;
  final HapticIntensityPreset intensityPreset;
  final bool cobbleRhythmEnabled;
  final bool impactAlertsEnabled;
  final bool mechanicalClicksEnabled;
  final bool isCobbleRhythmActive;
  final int activeCobbleStars;
  final double activeCobbleSpeedKmh;
  final String? activeCobbleSectorName;
  final int totalPulsesDispatched;
  final HapticVibrationEventRecord? lastEvent;
  final List<HapticVibrationEventRecord> history;

  const HapticVibrationState({
    this.isEnabled = true,
    this.intensityPreset = HapticIntensityPreset.balanced,
    this.cobbleRhythmEnabled = true,
    this.impactAlertsEnabled = true,
    this.mechanicalClicksEnabled = true,
    this.isCobbleRhythmActive = false,
    this.activeCobbleStars = 0,
    this.activeCobbleSpeedKmh = 0.0,
    this.activeCobbleSectorName,
    this.totalPulsesDispatched = 0,
    this.lastEvent,
    this.history = const <HapticVibrationEventRecord>[],
  });

  bool get isEffectivelyActive =>
      isEnabled && intensityPreset != HapticIntensityPreset.off;

  HapticVibrationState copyWith({
    bool? isEnabled,
    HapticIntensityPreset? intensityPreset,
    bool? cobbleRhythmEnabled,
    bool? impactAlertsEnabled,
    bool? mechanicalClicksEnabled,
    bool? isCobbleRhythmActive,
    int? activeCobbleStars,
    double? activeCobbleSpeedKmh,
    String? activeCobbleSectorName,
    bool clearActiveSectorName = false,
    int? totalPulsesDispatched,
    HapticVibrationEventRecord? lastEvent,
    List<HapticVibrationEventRecord>? history,
  }) {
    return HapticVibrationState(
      isEnabled: isEnabled ?? this.isEnabled,
      intensityPreset: intensityPreset ?? this.intensityPreset,
      cobbleRhythmEnabled: cobbleRhythmEnabled ?? this.cobbleRhythmEnabled,
      impactAlertsEnabled: impactAlertsEnabled ?? this.impactAlertsEnabled,
      mechanicalClicksEnabled:
          mechanicalClicksEnabled ?? this.mechanicalClicksEnabled,
      isCobbleRhythmActive: isCobbleRhythmActive ?? this.isCobbleRhythmActive,
      activeCobbleStars: activeCobbleStars ?? this.activeCobbleStars,
      activeCobbleSpeedKmh: activeCobbleSpeedKmh ?? this.activeCobbleSpeedKmh,
      activeCobbleSectorName: clearActiveSectorName
          ? null
          : (activeCobbleSectorName ?? this.activeCobbleSectorName),
      totalPulsesDispatched:
          totalPulsesDispatched ?? this.totalPulsesDispatched,
      lastEvent: lastEvent ?? this.lastEvent,
      history: history ?? this.history,
    );
  }
}

/// Globalny provider Riverpod kontrolera haptyki i wibracji.
final hapticFeedbackVibrationProvider = StateNotifierProvider<
    HapticFeedbackVibrationController, HapticVibrationState>(
  (ref) => HapticFeedbackVibrationController(),
);

/// Kontroler haptyki i wibracji oparty o [HapticFeedback] we Flutterze.
///
/// Obsługuje:
/// - subtelne, rytmiczne impulsy na sektorach bruku (szczególnie 5★),
/// - mocne sekwencje uderzeniowe przy kraksie lub ataku rywala ("Watt Bomb"),
/// - mechaniczne kliknięcia przy zmianie przełożeń i wydawaniu rozkazów.
class HapticFeedbackVibrationController
    extends StateNotifier<HapticVibrationState> {
  static const int _maxHistoryEntries = 48;

  final HapticDispatchCallback _dispatcher;
  final List<Timer> _sequenceTimers = <Timer>[];
  Timer? _cobbleRhythmTimer;
  int _cobbleTickCounter = 0;
  DateTime? _lastMechanicalClickAt;
  DateTime? _lastImpactAt;

  HapticFeedbackVibrationController({
    HapticDispatchCallback? dispatcher,
    bool initialEnabled = true,
    HapticIntensityPreset initialPreset = HapticIntensityPreset.balanced,
  })  : _dispatcher = dispatcher ?? _defaultFlutterHapticDispatcher,
        super(
          HapticVibrationState(
            isEnabled: initialEnabled,
            intensityPreset: initialPreset,
          ),
        );

  static Future<void> _defaultFlutterHapticDispatcher(
    HapticPulseType pulseType,
  ) async {
    try {
      switch (pulseType) {
        case HapticPulseType.lightImpact:
          await HapticFeedback.lightImpact();
        case HapticPulseType.mediumImpact:
          await HapticFeedback.mediumImpact();
        case HapticPulseType.heavyImpact:
          await HapticFeedback.heavyImpact();
        case HapticPulseType.selectionClick:
          await HapticFeedback.selectionClick();
        case HapticPulseType.vibrate:
          await HapticFeedback.vibrate();
      }
    } catch (_) {
      // Ignorujemy wyjątki platformowe na urządzeniach bez silnika haptycznego.
    }
  }

  /// Oblicza odstęp czasowy między rytmicznymi impulsami na bruku.
  ///
  /// Sektor 5★ przy wyższej prędkości generuje gęstszy, bardziej wyrazisty rytm
  /// (ok. 150–230 ms), natomiast łagodniejsze sektory 1–3★ dają rzadsze impulsy.
  static Duration computeCobblePulseInterval({
    required int sectorStars,
    required double speedKmh,
  }) {
    final clampedStars = sectorStars.clamp(1, 5);
    final clampedSpeed = speedKmh.clamp(12.0, 65.0);
    final baseMs = 430 - (clampedStars * 44);
    final speedFactor = 1.0 - ((clampedSpeed - 12.0) / 53.0) * 0.34;
    final intervalMs = (baseMs * speedFactor).round().clamp(140, 460);
    return Duration(milliseconds: intervalMs);
  }

  /// Uruchamia rytmiczne, subtelne impulsy haptyczne przy wjeździe na sektor bruku.
  void startCobbleSectorRhythm({
    required int sectorStars,
    double speedKmh = 40.0,
    String? sectorName,
  }) {
    final clampedStars = sectorStars.clamp(1, 5);
    final clampedSpeed = speedKmh.clamp(12.0, 65.0);

    _cancelCobbleTimer();
    _cobbleTickCounter = 0;

    state = state.copyWith(
      isCobbleRhythmActive: true,
      activeCobbleStars: clampedStars,
      activeCobbleSpeedKmh: clampedSpeed,
      activeCobbleSectorName: sectorName ?? 'Sektor bruku $clampedStars★',
    );

    if (!state.isEffectivelyActive || !state.cobbleRhythmEnabled) {
      return;
    }

    _emitCobbleRhythmPulse(
      sectorStars: clampedStars,
      speedKmh: clampedSpeed,
      sectorName: state.activeCobbleSectorName,
    );

    final interval = computeCobblePulseInterval(
      sectorStars: clampedStars,
      speedKmh: clampedSpeed,
    );

    _cobbleRhythmTimer = Timer.periodic(interval, (_) {
      if (!mounted ||
          !state.isCobbleRhythmActive ||
          !state.isEffectivelyActive ||
          !state.cobbleRhythmEnabled) {
        _cancelCobbleTimer();
        return;
      }
      _emitCobbleRhythmPulse(
        sectorStars: state.activeCobbleStars,
        speedKmh: state.activeCobbleSpeedKmh,
        sectorName: state.activeCobbleSectorName,
      );
    });
  }

  /// Aktualizuje parametry rytmu bruku w trakcie jazdy (np. zmiana prędkości lub wyjazd).
  void updateCobbleSectorTelemetry({
    required int sectorStars,
    required double speedKmh,
    String? sectorName,
  }) {
    if (sectorStars <= 0) {
      stopCobbleSectorRhythm();
      return;
    }

    final clampedStars = sectorStars.clamp(1, 5);
    final clampedSpeed = speedKmh.clamp(12.0, 65.0);
    final speedDelta = (clampedSpeed - state.activeCobbleSpeedKmh).abs();

    if (!state.isCobbleRhythmActive ||
        clampedStars != state.activeCobbleStars ||
        speedDelta >= 5.0) {
      startCobbleSectorRhythm(
        sectorStars: clampedStars,
        speedKmh: clampedSpeed,
        sectorName: sectorName ?? state.activeCobbleSectorName,
      );
    }
  }

  /// Wyzwala pojedynczy impuls rytmu brukowego bez uruchamiania timera.
  void triggerSingleCobbleImpulse({
    int sectorStars = 5,
    double speedKmh = 42.0,
    String? sectorName,
  }) {
    if (!state.isEffectivelyActive || !state.cobbleRhythmEnabled) return;
    _emitCobbleRhythmPulse(
      sectorStars: sectorStars.clamp(1, 5),
      speedKmh: speedKmh.clamp(12.0, 65.0),
      sectorName: sectorName ?? 'Sektor bruku ${sectorStars.clamp(1, 5)}★',
    );
  }

  /// Zatrzymuje rytmiczne impulsy po zjechaniu z sektora bruku.
  void stopCobbleSectorRhythm() {
    _cancelCobbleTimer();
    if (!state.isCobbleRhythmActive && state.activeCobbleStars == 0) {
      return;
    }
    state = state.copyWith(
      isCobbleRhythmActive: false,
      activeCobbleStars: 0,
      activeCobbleSpeedKmh: 0.0,
      clearActiveSectorName: true,
    );
  }

  void _emitCobbleRhythmPulse({
    required int sectorStars,
    required double speedKmh,
    String? sectorName,
  }) {
    _cobbleTickCounter++;
    final bool isAccentBeat =
        sectorStars >= 5 && (_cobbleTickCounter % 3 == 1);
    final HapticPulseType pulseType;

    if (sectorStars >= 5) {
      if (isAccentBeat &&
          state.intensityPreset == HapticIntensityPreset.proTactile) {
        pulseType = HapticPulseType.mediumImpact;
      } else {
        pulseType = _cobbleTickCounter.isEven
            ? HapticPulseType.selectionClick
            : HapticPulseType.lightImpact;
      }
    } else if (sectorStars >= 3) {
      pulseType = HapticPulseType.lightImpact;
    } else {
      pulseType = HapticPulseType.selectionClick;
    }

    final double baseIntensity = 0.28 + (sectorStars * 0.09);
    _dispatchPulse(
      category: HapticEventCategory.cobbleSectorRhythm,
      pulseType: pulseType,
      description:
          '${sectorName ?? 'Bruk $sectorStars★'} (${speedKmh.toStringAsFixed(0)} km/h)',
      intensity: (baseIntensity * state.intensityPreset.scale).clamp(0.1, 1.0),
    );
  }

  /// Wyzwala mocne uderzenie haptyczne przy kraksie kolarza lub peletonu.
  void triggerCrashImpact({
    String? riderName,
    double severity = 1.0,
  }) {
    if (!state.isEffectivelyActive || !state.impactAlertsEnabled) return;
    if (!_canTriggerImpact()) return;

    final clampedSeverity = severity.clamp(0.25, 1.0);
    final scale = state.intensityPreset.scale;
    final targetLabel =
        riderName != null && riderName.isNotEmpty ? ' ($riderName)' : '';
    final totalPulses = clampedSeverity >= 0.75 ? 3 : 2;

    _dispatchPulse(
      category: HapticEventCategory.crashImpact,
      pulseType: HapticPulseType.heavyImpact,
      description: 'Kraksa na trasie$targetLabel',
      intensity: (1.0 * scale).clamp(0.2, 1.0),
      sequenceIndex: 1,
      totalInSequence: totalPulses,
    );

    _scheduleSequencePulse(
      delay: const Duration(milliseconds: 75),
      category: HapticEventCategory.crashImpact,
      pulseType: HapticPulseType.heavyImpact,
      description: 'Wtórne uderzenie kraksy$targetLabel',
      intensity: (0.9 * scale).clamp(0.2, 1.0),
      sequenceIndex: 2,
      totalInSequence: totalPulses,
    );

    if (totalPulses == 3) {
      _scheduleSequencePulse(
        delay: const Duration(milliseconds: 165),
        category: HapticEventCategory.crashImpact,
        pulseType: scale >= 0.8
            ? HapticPulseType.vibrate
            : HapticPulseType.mediumImpact,
        description: 'Wstrząs końcowy kraksy$targetLabel',
        intensity: (0.85 * scale).clamp(0.2, 1.0),
        sequenceIndex: 3,
        totalInSequence: totalPulses,
      );
    }
  }

  /// Wyzwala mocny impuls ostrzegawczy przy ataku rywala ("Watt Bomb").
  void triggerWattBombAttack({
    String? attackerName,
    double wattsPerKg = 13.4,
    double peakWatts = 1420.0,
  }) {
    if (!state.isEffectivelyActive || !state.impactAlertsEnabled) return;
    if (!_canTriggerImpact()) return;

    final scale = state.intensityPreset.scale;
    final who = attackerName != null && attackerName.isNotEmpty
        ? '$attackerName '
        : '';
    final metrics =
        '${wattsPerKg.toStringAsFixed(1)} W/kg (${peakWatts.toStringAsFixed(0)} W)';

    _dispatchPulse(
      category: HapticEventCategory.wattBombAttack,
      pulseType: HapticPulseType.heavyImpact,
      description: 'Watt Bomb: $who$metrics',
      intensity: (0.95 * scale).clamp(0.2, 1.0),
      sequenceIndex: 1,
      totalInSequence: 2,
    );

    _scheduleSequencePulse(
      delay: const Duration(milliseconds: 65),
      category: HapticEventCategory.wattBombAttack,
      pulseType: scale >= 0.85
          ? HapticPulseType.heavyImpact
          : HapticPulseType.mediumImpact,
      description: 'Impuls przyspieszenia: $who$metrics',
      intensity: (0.80 * scale).clamp(0.2, 1.0),
      sequenceIndex: 2,
      totalInSequence: 2,
    );
  }

  /// Wyzwala mechaniczne kliknięcie przy zmianie przełożenia (przerzutka przednia/tylna).
  void triggerGearShiftClick({
    int? frontChainringTeeth,
    int? rearCogTeeth,
    bool isFrontDerailleur = false,
  }) {
    if (!state.isEffectivelyActive || !state.mechanicalClicksEnabled) return;
    if (!_canTriggerMechanicalClick()) return;

    final gearLabel =
        (frontChainringTeeth != null && rearCogTeeth != null)
            ? ' ($frontChainringTeeth/${rearCogTeeth}T)'
            : '';

    final pulseType = isFrontDerailleur
        ? HapticPulseType.mediumImpact
        : HapticPulseType.selectionClick;

    _dispatchPulse(
      category: HapticEventCategory.gearShift,
      pulseType: pulseType,
      description: isFrontDerailleur
          ? 'Zmiana tarczy korby$gearLabel'
          : 'Kliknięcie kasety$gearLabel',
      intensity:
          ((isFrontDerailleur ? 0.65 : 0.45) * state.intensityPreset.scale)
              .clamp(0.1, 1.0),
    );
  }

  /// Wyzwala mechaniczne kliknięcie przy wydaniu rozkazu taktycznego z radia/HUD.
  void triggerTacticalOrderClick({
    required String orderLabel,
    bool isHighPriority = false,
  }) {
    if (!state.isEffectivelyActive || !state.mechanicalClicksEnabled) return;
    if (!_canTriggerMechanicalClick()) return;

    final cleanLabel =
        orderLabel.trim().isEmpty ? 'Rozkaz taktyczny' : orderLabel.trim();

    _dispatchPulse(
      category: HapticEventCategory.tacticalOrder,
      pulseType: isHighPriority
          ? HapticPulseType.mediumImpact
          : HapticPulseType.selectionClick,
      description: 'Rozkaz: $cleanLabel',
      intensity:
          ((isHighPriority ? 0.72 : 0.50) * state.intensityPreset.scale)
              .clamp(0.1, 1.0),
    );
  }

  /// Włącza lub wyłącza globalnie kontroler haptyki.
  void setEnabled(bool enabled) {
    if (!enabled) {
      _cancelCobbleTimer();
      _cancelSequenceTimers();
    }
    state = state.copyWith(
      isEnabled: enabled,
      isCobbleRhythmActive: enabled ? state.isCobbleRhythmActive : false,
    );
  }

  /// Zmienia profil intensywności wibracji.
  void setIntensityPreset(HapticIntensityPreset preset) {
    if (preset == HapticIntensityPreset.off) {
      _cancelCobbleTimer();
      _cancelSequenceTimers();
    }
    state = state.copyWith(
      intensityPreset: preset,
      isCobbleRhythmActive: preset == HapticIntensityPreset.off
          ? false
          : state.isCobbleRhythmActive,
    );
  }

  /// Włącza lub wyłącza poszczególne kategorie efektów haptycznych.
  void setCategoryEnabled({
    bool? cobbleRhythm,
    bool? impactAlerts,
    bool? mechanicalClicks,
  }) {
    if (cobbleRhythm == false) {
      _cancelCobbleTimer();
    }
    state = state.copyWith(
      cobbleRhythmEnabled: cobbleRhythm,
      impactAlertsEnabled: impactAlerts,
      mechanicalClicksEnabled: mechanicalClicks,
      isCobbleRhythmActive: cobbleRhythm == false
          ? false
          : state.isCobbleRhythmActive,
    );
  }

  /// Czyści dziennik zdarzeń haptycznych.
  void clearHistory() {
    state = state.copyWith(
      history: const <HapticVibrationEventRecord>[],
    );
  }

  bool _canTriggerImpact() {
    final now = DateTime.now();
    if (_lastImpactAt != null &&
        now.difference(_lastImpactAt!) < const Duration(milliseconds: 120)) {
      return false;
    }
    _lastImpactAt = now;
    return true;
  }

  bool _canTriggerMechanicalClick() {
    final now = DateTime.now();
    if (_lastMechanicalClickAt != null &&
        now.difference(_lastMechanicalClickAt!) <
            const Duration(milliseconds: 35)) {
      return false;
    }
    _lastMechanicalClickAt = now;
    return true;
  }

  void _scheduleSequencePulse({
    required Duration delay,
    required HapticEventCategory category,
    required HapticPulseType pulseType,
    required String description,
    required double intensity,
    required int sequenceIndex,
    required int totalInSequence,
  }) {
    late final Timer timer;
    timer = Timer(delay, () {
      _sequenceTimers.remove(timer);
      if (!mounted || !state.isEffectivelyActive) return;
      _dispatchPulse(
        category: category,
        pulseType: pulseType,
        description: description,
        intensity: intensity,
        sequenceIndex: sequenceIndex,
        totalInSequence: totalInSequence,
      );
    });
    _sequenceTimers.add(timer);
  }

  void _dispatchPulse({
    required HapticEventCategory category,
    required HapticPulseType pulseType,
    required String description,
    required double intensity,
    int sequenceIndex = 1,
    int totalInSequence = 1,
  }) {
    unawaited(_dispatcher(pulseType));

    final record = HapticVibrationEventRecord(
      timestamp: DateTime.now(),
      category: category,
      pulseType: pulseType,
      description: description,
      intensity: intensity,
      sequenceIndex: sequenceIndex,
      totalInSequence: totalInSequence,
    );

    final updatedHistory = <HapticVibrationEventRecord>[
      record,
      ...state.history,
    ];
    if (updatedHistory.length > _maxHistoryEntries) {
      updatedHistory.removeRange(_maxHistoryEntries, updatedHistory.length);
    }

    state = state.copyWith(
      totalPulsesDispatched: state.totalPulsesDispatched + 1,
      lastEvent: record,
      history: List<HapticVibrationEventRecord>.unmodifiable(updatedHistory),
    );
  }

  void _cancelCobbleTimer() {
    _cobbleRhythmTimer?.cancel();
    _cobbleRhythmTimer = null;
  }

  void _cancelSequenceTimers() {
    for (final timer in _sequenceTimers) {
      timer.cancel();
    }
    _sequenceTimers.clear();
  }

  @override
  void dispose() {
    _cancelCobbleTimer();
    _cancelSequenceTimers();
    super.dispose();
  }
}

/// Panel sterowania i testowania haptyki w stylu Pro Peloton Manager.
///
/// Pełna responsywność dla `390x844`, `1024x768` oraz `1600x900` z obsługą stanów
/// `hover`, `active`, `disabled` i `focus`.
class HapticFeedbackControlPanel extends ConsumerWidget {
  const HapticFeedbackControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hapticState = ref.watch(hapticFeedbackVibrationProvider);
    final controller = ref.read(hapticFeedbackVibrationProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final isCompact = width < 640;
        final isWide = width >= 1100;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, hapticState, controller, isCompact),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildSettingsSection(
                        hapticState,
                        controller,
                        isCompact,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 7,
                      child: _buildTriggersAndLogSection(
                        hapticState,
                        controller,
                        isCompact,
                      ),
                    ),
                  ],
                )
              else ...[
                _buildSettingsSection(hapticState, controller, isCompact),
                const SizedBox(height: 16),
                _buildTriggersAndLogSection(
                  hapticState,
                  controller,
                  isCompact,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    HapticVibrationState state,
    HapticFeedbackVibrationController controller,
    bool isCompact,
  ) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: state.isEffectivelyActive
                    ? AppColors.goldAccent.withValues(alpha: 0.14)
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: state.isEffectivelyActive
                      ? AppColors.goldAccent.withValues(alpha: 0.5)
                      : AppColors.cardBorder,
                ),
              ),
              child: Icon(
                Icons.vibration_rounded,
                size: 20,
                color: state.isEffectivelyActive
                    ? AppColors.goldAccent
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kontroler Haptyki i Wibracji',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.isCobbleRhythmActive
                        ? 'Aktywny rytm: ${state.activeCobbleSectorName ?? "Bruk 5★"}'
                        : 'Impulsy wysłane: ${state.totalPulsesDispatched}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: state.isCobbleRhythmActive
                          ? AppColors.amberWarning
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _HapticActionButton(
          label: state.isEnabled ? 'Haptyka Włączona' : 'Haptyka Wyłączona',
          icon: state.isEnabled ? Icons.sensors_rounded : Icons.sensors_off,
          isActive: state.isEnabled,
          accentColor: state.isEnabled
              ? AppColors.statusSuccess
              : AppColors.textSecondary,
          onPressed: () => controller.setEnabled(!state.isEnabled),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(
    HapticVibrationState state,
    HapticFeedbackVibrationController controller,
    bool isCompact,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Profil Intensywności',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: HapticIntensityPreset.values.map((preset) {
              final isSelected = state.intensityPreset == preset;
              return _HapticActionButton(
                label: preset.label,
                isActive: isSelected,
                isDisabled: !state.isEnabled,
                accentColor: AppColors.goldAccent,
                onPressed: () => controller.setIntensityPreset(preset),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kanały Zdarzeń Wyścigowych',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _CategorySwitchTile(
            title: 'Rytm bruku 5★',
            subtitle: 'Subtelne impulsy zależne od prędkości i gwiazdek',
            value: state.cobbleRhythmEnabled,
            enabled: state.isEffectivelyActive,
            onChanged: (v) => controller.setCategoryEnabled(cobbleRhythm: v),
          ),
          const SizedBox(height: 8),
          _CategorySwitchTile(
            title: 'Kraksy i ataki "Watt Bomb"',
            subtitle: 'Mocne uderzenia przy incydentach i przyspieszeniach',
            value: state.impactAlertsEnabled,
            enabled: state.isEffectivelyActive,
            onChanged: (v) => controller.setCategoryEnabled(impactAlerts: v),
          ),
          const SizedBox(height: 8),
          _CategorySwitchTile(
            title: 'Przełożenia i rozkazy',
            subtitle: 'Mechaniczne kliknięcia kasety, korby i radia',
            value: state.mechanicalClicksEnabled,
            enabled: state.isEffectivelyActive,
            onChanged: (v) =>
                controller.setCategoryEnabled(mechanicalClicks: v),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggersAndLogSection(
    HapticVibrationState state,
    HapticFeedbackVibrationController controller,
    bool isCompact,
  ) {
    final canCobble = state.isEffectivelyActive && state.cobbleRhythmEnabled;
    final canImpact = state.isEffectivelyActive && state.impactAlertsEnabled;
    final canMech =
        state.isEffectivelyActive && state.mechanicalClicksEnabled;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Symulacja Impulsów',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              if (state.history.isNotEmpty)
                _HapticActionButton(
                  label: 'Wyczyść log',
                  icon: Icons.delete_sweep_outlined,
                  accentColor: AppColors.textSecondary,
                  onPressed: controller.clearHistory,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HapticActionButton(
                label: state.isCobbleRhythmActive
                    ? 'Zatrzymaj Bruk 5★'
                    : 'Bruk 5★ (Arenberg)',
                icon: Icons.grain_rounded,
                isActive: state.isCobbleRhythmActive,
                isDisabled: !canCobble,
                accentColor: AppColors.amberWarning,
                onPressed: () {
                  if (state.isCobbleRhythmActive) {
                    controller.stopCobbleSectorRhythm();
                  } else {
                    controller.startCobbleSectorRhythm(
                      sectorStars: 5,
                      speedKmh: 44.0,
                      sectorName: 'Trouée d\'Arenberg 5★',
                    );
                  }
                },
              ),
              _HapticActionButton(
                label: 'Kraksa (Heavy)',
                icon: Icons.warning_amber_rounded,
                isDisabled: !canImpact,
                accentColor: AppColors.crimsonAlert,
                onPressed: () => controller.triggerCrashImpact(
                  riderName: 'Lider',
                  severity: 1.0,
                ),
              ),
              _HapticActionButton(
                label: 'Watt Bomb',
                icon: Icons.bolt_rounded,
                isDisabled: !canImpact,
                accentColor: AppColors.primaryAccent,
                onPressed: () => controller.triggerWattBombAttack(
                  attackerName: 'Rywal GC',
                  wattsPerKg: 13.8,
                  peakWatts: 1480,
                ),
              ),
              _HapticActionButton(
                label: 'Zmiana biegu',
                icon: Icons.settings_rounded,
                isDisabled: !canMech,
                accentColor: AppColors.accentBlue,
                onPressed: () => controller.triggerGearShiftClick(
                  frontChainringTeeth: 54,
                  rearCogTeeth: 13,
                ),
              ),
              _HapticActionButton(
                label: 'Rozkaz: Atakuj',
                icon: Icons.campaign_rounded,
                isDisabled: !canMech,
                accentColor: AppColors.statusSuccess,
                onPressed: () => controller.triggerTacticalOrderClick(
                  orderLabel: 'Atakuj na podjeździe',
                  isHighPriority: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Ostatnie zdarzenia haptyczne',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (state.history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Text(
                'Brak wyemitowanych impulsów. Uruchom test lub rozpocznij etap.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: state.history
                  .take(math.min(4, state.history.length))
                  .map((entry) => _HapticEventRow(record: entry))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _CategorySwitchTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _CategorySwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_CategorySwitchTile> createState() => _CategorySwitchTileState();
}

class _CategorySwitchTileState extends State<_CategorySwitchTile> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final effectiveActive = widget.enabled && widget.value;
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _isHovered && widget.enabled
              ? AppColors.background.withValues(alpha: 0.7)
              : AppColors.background.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isFocused
                ? AppColors.goldAccent
                : (effectiveActive
                    ? AppColors.cardBorder
                    : AppColors.cardBorder.withValues(alpha: 0.5)),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: widget.enabled
                          ? AppColors.textSecondary
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: widget.value,
              onChanged: widget.enabled ? widget.onChanged : null,
              activeThumbColor: AppColors.goldAccent,
              activeTrackColor: AppColors.goldAccent.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _HapticActionButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isActive;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onPressed;

  const _HapticActionButton({
    required this.label,
    required this.accentColor,
    required this.onPressed,
    this.icon,
    this.isActive = false,
    this.isDisabled = false,
  });

  @override
  State<_HapticActionButton> createState() => _HapticActionButtonState();
}

class _HapticActionButtonState extends State<_HapticActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color borderColor;
    final Color fgColor;

    if (widget.isDisabled) {
      bgColor = AppColors.background.withValues(alpha: 0.35);
      borderColor = AppColors.cardBorder.withValues(alpha: 0.4);
      fgColor = AppColors.textSecondary.withValues(alpha: 0.45);
    } else if (widget.isActive) {
      bgColor = widget.accentColor.withValues(alpha: _isHovered ? 0.28 : 0.20);
      borderColor = widget.accentColor;
      fgColor = AppColors.textPrimary;
    } else {
      bgColor = _isPressed
          ? widget.accentColor.withValues(alpha: 0.22)
          : (_isHovered
              ? AppColors.surface
              : AppColors.background.withValues(alpha: 0.65));
      borderColor = _isFocused
          ? AppColors.goldAccent
          : (_isHovered ? widget.accentColor.withValues(alpha: 0.7) : AppColors.cardBorder);
      fgColor = AppColors.textPrimary;
    }

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _isHovered = v),
      onShowFocusHighlight: (v) => setState(() => _isFocused = v),
      child: GestureDetector(
        onTapDown: widget.isDisabled ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.isDisabled ? null : () => setState(() => _isPressed = false),
        onTap: widget.isDisabled ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: widget.isDisabled ? fgColor : widget.accentColor,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: fgColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HapticEventRow extends StatelessWidget {
  final HapticVibrationEventRecord record;

  const _HapticEventRow({required this.record});

  Color _categoryColor(HapticEventCategory category) {
    switch (category) {
      case HapticEventCategory.cobbleSectorRhythm:
        return AppColors.amberWarning;
      case HapticEventCategory.crashImpact:
        return AppColors.crimsonAlert;
      case HapticEventCategory.wattBombAttack:
        return AppColors.primaryAccent;
      case HapticEventCategory.gearShift:
        return AppColors.accentBlue;
      case HapticEventCategory.tacticalOrder:
        return AppColors.statusSuccess;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = _categoryColor(record.category);
    final hh = record.timestamp.hour.toString().padLeft(2, '0');
    final mm = record.timestamp.minute.toString().padLeft(2, '0');
    final ss = record.timestamp.second.toString().padLeft(2, '0');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              record.description,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 2,
            child: Text(
              '${record.pulseType.label} · $hh:$mm:$ss',
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
