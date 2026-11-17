// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';

/// Kategoria makra taktycznego dla całej drużyny.
enum TacticalMacroCategory {
  attack,
  sprintLeadout,
  mountainTrain,
  echelon,
  recovery,
  custom;

  String get label {
    switch (this) {
      case TacticalMacroCategory.attack:
        return 'Atak';
      case TacticalMacroCategory.sprintLeadout:
        return 'Sprint';
      case TacticalMacroCategory.mountainTrain:
        return 'Góry';
      case TacticalMacroCategory.echelon:
        return 'Wachlarz';
      case TacticalMacroCategory.recovery:
        return 'Regeneracja';
      case TacticalMacroCategory.custom:
        return 'Własne';
    }
  }

  IconData get icon {
    switch (this) {
      case TacticalMacroCategory.attack:
        return Icons.flash_on_rounded;
      case TacticalMacroCategory.sprintLeadout:
        return Icons.fast_forward_rounded;
      case TacticalMacroCategory.mountainTrain:
        return Icons.terrain_rounded;
      case TacticalMacroCategory.echelon:
        return Icons.air_rounded;
      case TacticalMacroCategory.recovery:
        return Icons.battery_charging_full_rounded;
      case TacticalMacroCategory.custom:
        return Icons.tune_rounded;
    }
  }

  Color get accentColor {
    switch (this) {
      case TacticalMacroCategory.attack:
        return AppColors.crimsonAlert;
      case TacticalMacroCategory.sprintLeadout:
        return AppColors.goldAccent;
      case TacticalMacroCategory.mountainTrain:
        return AppColors.powerZone5;
      case TacticalMacroCategory.echelon:
        return AppColors.cyanAccent;
      case TacticalMacroCategory.recovery:
        return AppColors.statusSuccess;
      case TacticalMacroCategory.custom:
        return AppColors.accentBlue;
    }
  }

  String toJson() => name;

  static TacticalMacroCategory fromJson(String? value) {
    return TacticalMacroCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => TacticalMacroCategory.custom,
    );
  }
}

/// Warunek wyzwolenia pojedynczego kroku makra taktycznego.
enum MacroTriggerCondition {
  immediate,
  afterDelay,
  atKilometerMark,
  onClimbStart;

  String get label {
    switch (this) {
      case MacroTriggerCondition.immediate:
        return 'Natychmiast';
      case MacroTriggerCondition.afterDelay:
        return 'Opóźnienie (s)';
      case MacroTriggerCondition.atKilometerMark:
        return 'Dystans (km)';
      case MacroTriggerCondition.onClimbStart:
        return 'Start podjazdu';
    }
  }

  String toJson() => name;

  static MacroTriggerCondition fromJson(String? value) {
    return MacroTriggerCondition.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => MacroTriggerCondition.immediate,
    );
  }
}

/// Faza pracy nagrywarki makr taktycznych.
enum MacroRecorderPhase {
  idle,
  recording,
  paused,
  playback,
}

/// Docelowa grupa lub pojedynczy kolarz w kroku makra.
class MacroTargetScope {
  static const String allTeam = 'ALL_TEAM';
  static const String leadersOnly = 'LEADERS_ONLY';
  static const String domestiquesOnly = 'DOMESTIQUES_ONLY';

  static String labelFor(String targetId, String? riderName) {
    switch (targetId) {
      case allTeam:
        return 'Cała drużyna';
      case leadersOnly:
        return 'Liderzy';
      case domestiquesOnly:
        return 'Pomocnicy';
      default:
        return riderName ?? targetId;
    }
  }
}

/// Lekki opis kolarza drużyny dostępnego w nagrywarce makr.
class MacroTeamRiderSlot {
  final String id;
  final String name;
  final int bibNumber;
  final String roleLabel;
  final bool isLeader;
  final int ftpWatts;
  final TacticalOrder currentOrder;
  final double currentEffortPercent;
  final bool isActive;

  const MacroTeamRiderSlot({
    required this.id,
    required this.name,
    required this.bibNumber,
    required this.roleLabel,
    this.isLeader = false,
    this.ftpWatts = 380,
    this.currentOrder = TacticalOrder.holdPosition,
    this.currentEffortPercent = 75.0,
    this.isActive = true,
  });

  MacroTeamRiderSlot copyWith({
    TacticalOrder? currentOrder,
    double? currentEffortPercent,
    bool? isActive,
  }) {
    return MacroTeamRiderSlot(
      id: id,
      name: name,
      bibNumber: bibNumber,
      roleLabel: roleLabel,
      isLeader: isLeader,
      ftpWatts: ftpWatts,
      currentOrder: currentOrder ?? this.currentOrder,
      currentEffortPercent: currentEffortPercent ?? this.currentEffortPercent,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Pojedynczy zarejestrowany krok rozkazu taktycznego w makrze.
class TacticalMacroStep {
  final String id;
  final int stepIndex;
  final String targetId;
  final String targetLabel;
  final int? bibNumber;
  final TacticalOrder order;
  final double targetEffortPercent;
  final int offsetMilliseconds;
  final MacroTriggerCondition triggerCondition;
  final double? triggerKmMark;
  final String? note;

  const TacticalMacroStep({
    required this.id,
    required this.stepIndex,
    required this.targetId,
    required this.targetLabel,
    this.bibNumber,
    required this.order,
    required this.targetEffortPercent,
    this.offsetMilliseconds = 0,
    this.triggerCondition = MacroTriggerCondition.immediate,
    this.triggerKmMark,
    this.note,
  });

  Duration get offsetDuration => Duration(milliseconds: offsetMilliseconds);

  TacticalMacroStep copyWith({
    String? id,
    int? stepIndex,
    String? targetId,
    String? targetLabel,
    int? bibNumber,
    TacticalOrder? order,
    double? targetEffortPercent,
    int? offsetMilliseconds,
    MacroTriggerCondition? triggerCondition,
    double? triggerKmMark,
    String? note,
  }) {
    return TacticalMacroStep(
      id: id ?? this.id,
      stepIndex: stepIndex ?? this.stepIndex,
      targetId: targetId ?? this.targetId,
      targetLabel: targetLabel ?? this.targetLabel,
      bibNumber: bibNumber ?? this.bibNumber,
      order: order ?? this.order,
      targetEffortPercent: targetEffortPercent ?? this.targetEffortPercent,
      offsetMilliseconds: offsetMilliseconds ?? this.offsetMilliseconds,
      triggerCondition: triggerCondition ?? this.triggerCondition,
      triggerKmMark: triggerKmMark ?? this.triggerKmMark,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stepIndex': stepIndex,
      'targetId': targetId,
      'targetLabel': targetLabel,
      'bibNumber': bibNumber,
      'order': order.toJson(),
      'targetEffortPercent': targetEffortPercent,
      'offsetMilliseconds': offsetMilliseconds,
      'triggerCondition': triggerCondition.toJson(),
      'triggerKmMark': triggerKmMark,
      'note': note,
    };
  }

  factory TacticalMacroStep.fromJson(Map<String, dynamic> json) {
    return TacticalMacroStep(
      id: (json['id'] as String?) ?? 'step_0',
      stepIndex: (json['stepIndex'] as num?)?.toInt() ?? 0,
      targetId: (json['targetId'] as String?) ?? MacroTargetScope.allTeam,
      targetLabel: (json['targetLabel'] as String?) ?? 'Cała drużyna',
      bibNumber: (json['bibNumber'] as num?)?.toInt(),
      order: TacticalOrder.fromJson((json['order'] as String?) ?? 'holdPosition'),
      targetEffortPercent:
          ((json['targetEffortPercent'] as num?)?.toDouble() ?? 80.0).clamp(50.0, 120.0),
      offsetMilliseconds: (json['offsetMilliseconds'] as num?)?.toInt() ?? 0,
      triggerCondition: MacroTriggerCondition.fromJson(json['triggerCondition'] as String?),
      triggerKmMark: (json['triggerKmMark'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }
}

/// Zapisane makro taktyczne uruchamiane jednym przyciskiem dla całej drużyny.
class QuickTacticalMacro {
  final String id;
  final String name;
  final String? hotkeyLabel;
  final TacticalMacroCategory category;
  final List<TacticalMacroStep> steps;
  final DateTime createdAt;
  final int executionCount;
  final bool isPinned;

  const QuickTacticalMacro({
    required this.id,
    required this.name,
    this.hotkeyLabel,
    required this.category,
    required this.steps,
    required this.createdAt,
    this.executionCount = 0,
    this.isPinned = true,
  });

  int get totalDurationMs {
    if (steps.isEmpty) return 0;
    int maxOffset = 0;
    for (final step in steps) {
      if (step.offsetMilliseconds > maxOffset) {
        maxOffset = step.offsetMilliseconds;
      }
    }
    return maxOffset;
  }

  Set<String> get affectedTargets => steps.map((s) => s.targetId).toSet();

  QuickTacticalMacro copyWith({
    String? id,
    String? name,
    String? hotkeyLabel,
    TacticalMacroCategory? category,
    List<TacticalMacroStep>? steps,
    DateTime? createdAt,
    int? executionCount,
    bool? isPinned,
  }) {
    return QuickTacticalMacro(
      id: id ?? this.id,
      name: name ?? this.name,
      hotkeyLabel: hotkeyLabel ?? this.hotkeyLabel,
      category: category ?? this.category,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
      executionCount: executionCount ?? this.executionCount,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hotkeyLabel': hotkeyLabel,
      'category': category.toJson(),
      'steps': steps.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'executionCount': executionCount,
      'isPinned': isPinned,
    };
  }

  factory QuickTacticalMacro.fromJson(Map<String, dynamic> json) {
    final rawSteps = (json['steps'] as List<dynamic>?) ?? const [];
    return QuickTacticalMacro(
      id: (json['id'] as String?) ?? 'macro_0',
      name: (json['name'] as String?) ?? 'Nowe Makro',
      hotkeyLabel: json['hotkeyLabel'] as String?,
      category: TacticalMacroCategory.fromJson(json['category'] as String?),
      steps: rawSteps
          .whereType<Map<String, dynamic>>()
          .map(TacticalMacroStep.fromJson)
          .toList(),
      createdAt: DateTime.tryParse((json['createdAt'] as String?) ?? '') ??
          DateTime(2026, 1, 1),
      executionCount: (json['executionCount'] as num?)?.toInt() ?? 0,
      isPinned: (json['isPinned'] as bool?) ?? true,
    );
  }
}

/// Wynik uruchomienia makra taktycznego na drużynie.
class MacroExecutionResult {
  final QuickTacticalMacro macro;
  final List<TacticalMacroStep> executedSteps;
  final int affectedRidersCount;
  final DateTime executedAt;
  final String radioBroadcast;

  const MacroExecutionResult({
    required this.macro,
    required this.executedSteps,
    required this.affectedRidersCount,
    required this.executedAt,
    required this.radioBroadcast,
  });
}

/// Walidator i menedżer serializacji/katalogu makr taktycznych.
class QuickTacticalMacroManager {
  QuickTacticalMacroManager._();

  static List<QuickTacticalMacro> defaultTeamMacros() {
    final now = DateTime(2026, 7, 14, 14, 0);
    return [
      QuickTacticalMacro(
        id: 'macro_sprint_3km',
        name: 'Pociąg Sprinterski 3 km',
        hotkeyLabel: 'M1',
        category: TacticalMacroCategory.sprintLeadout,
        createdAt: now,
        isPinned: true,
        steps: const [
          TacticalMacroStep(
            id: 's1',
            stepIndex: 0,
            targetId: MacroTargetScope.domestiquesOnly,
            targetLabel: 'Pomocnicy',
            order: TacticalOrder.pullGroup,
            targetEffortPercent: 105,
            offsetMilliseconds: 0,
            triggerCondition: MacroTriggerCondition.immediate,
            note: 'Wyjście lokomotyw na czoło peletonu',
          ),
          TacticalMacroStep(
            id: 's2',
            stepIndex: 1,
            targetId: MacroTargetScope.leadersOnly,
            targetLabel: 'Liderzy',
            order: TacticalOrder.followWheels,
            targetEffortPercent: 92,
            offsetMilliseconds: 1500,
            triggerCondition: MacroTriggerCondition.afterDelay,
            note: 'Sprinter chowa się w tunelu aerodynamicznym',
          ),
          TacticalMacroStep(
            id: 's3',
            stepIndex: 2,
            targetId: MacroTargetScope.leadersOnly,
            targetLabel: 'Liderzy',
            order: TacticalOrder.attack,
            targetEffortPercent: 118,
            offsetMilliseconds: 4500,
            triggerCondition: MacroTriggerCondition.afterDelay,
            note: 'Odpalenie sprintu na 200 m przed kreską',
          ),
        ],
      ),
      QuickTacticalMacro(
        id: 'macro_echelon_crosswind',
        name: 'Wachlarz na Rancie',
        hotkeyLabel: 'M2',
        category: TacticalMacroCategory.echelon,
        createdAt: now,
        isPinned: true,
        steps: const [
          TacticalMacroStep(
            id: 'e1',
            stepIndex: 0,
            targetId: MacroTargetScope.allTeam,
            targetLabel: 'Cała drużyna',
            order: TacticalOrder.pullGroup,
            targetEffortPercent: 102,
            offsetMilliseconds: 0,
            triggerCondition: MacroTriggerCondition.immediate,
            note: 'Cały skład na prawy rant wiatru bocznego',
          ),
          TacticalMacroStep(
            id: 'e2',
            stepIndex: 1,
            targetId: MacroTargetScope.domestiquesOnly,
            targetLabel: 'Pomocnicy',
            order: TacticalOrder.protectLeader,
            targetEffortPercent: 98,
            offsetMilliseconds: 2000,
            triggerCondition: MacroTriggerCondition.afterDelay,
            note: 'Osłona lidera GC w pierwszym wachlarzu',
          ),
        ],
      ),
      QuickTacticalMacro(
        id: 'macro_mountain_ambush',
        name: 'Kocioł na Przełęczy HC',
        hotkeyLabel: 'M3',
        category: TacticalMacroCategory.mountainTrain,
        createdAt: now,
        isPinned: true,
        steps: const [
          TacticalMacroStep(
            id: 'm1',
            stepIndex: 0,
            targetId: MacroTargetScope.domestiquesOnly,
            targetLabel: 'Pomocnicy',
            order: TacticalOrder.pullGroup,
            targetEffortPercent: 96,
            offsetMilliseconds: 0,
            triggerCondition: MacroTriggerCondition.onClimbStart,
            note: 'Selekcja na początku podjazdu',
          ),
          TacticalMacroStep(
            id: 'm2',
            stepIndex: 1,
            targetId: MacroTargetScope.leadersOnly,
            targetLabel: 'Liderzy',
            order: TacticalOrder.attack,
            targetEffortPercent: 112,
            offsetMilliseconds: 3000,
            triggerCondition: MacroTriggerCondition.afterDelay,
            note: 'Skok lidera po zużyciu ostatniego górala',
          ),
        ],
      ),
      QuickTacticalMacro(
        id: 'macro_full_recovery',
        name: 'Alarm: Bidony & Oszczędzanie',
        hotkeyLabel: 'M4',
        category: TacticalMacroCategory.recovery,
        createdAt: now,
        isPinned: true,
        steps: const [
          TacticalMacroStep(
            id: 'r1',
            stepIndex: 0,
            targetId: MacroTargetScope.allTeam,
            targetLabel: 'Cała drużyna',
            order: TacticalOrder.saveEnergy,
            targetEffortPercent: 65,
            offsetMilliseconds: 0,
            triggerCondition: MacroTriggerCondition.immediate,
            note: 'Schowanie w głębi peletonu',
          ),
          TacticalMacroStep(
            id: 'r2',
            stepIndex: 1,
            targetId: MacroTargetScope.domestiquesOnly,
            targetLabel: 'Pomocnicy',
            order: TacticalOrder.fetchBidonsFromCar,
            targetEffortPercent: 72,
            offsetMilliseconds: 1000,
            triggerCondition: MacroTriggerCondition.afterDelay,
            note: 'Zjazd po bidony i żele do wozu technicznego',
          ),
        ],
      ),
    ];
  }

  static List<MacroTeamRiderSlot> defaultRoster() {
    return const [
      MacroTeamRiderSlot(
        id: 'r_1',
        name: 'T. Pogačar',
        bibNumber: 1,
        roleLabel: 'Lider GC',
        isLeader: true,
        ftpWatts: 430,
      ),
      MacroTeamRiderSlot(
        id: 'r_2',
        name: 'R. Majka',
        bibNumber: 2,
        roleLabel: 'Góral',
        ftpWatts: 395,
      ),
      MacroTeamRiderSlot(
        id: 'r_3',
        name: 'J. Philipsen',
        bibNumber: 3,
        roleLabel: 'Sprinter',
        isLeader: true,
        ftpWatts: 405,
      ),
      MacroTeamRiderSlot(
        id: 'r_4',
        name: 'N. Politt',
        bibNumber: 4,
        roleLabel: 'Rouleur',
        ftpWatts: 415,
      ),
      MacroTeamRiderSlot(
        id: 'r_5',
        name: 'T. Wellens',
        bibNumber: 5,
        roleLabel: 'Klasyki',
        ftpWatts: 390,
      ),
      MacroTeamRiderSlot(
        id: 'r_6',
        name: 'M. Soler',
        bibNumber: 6,
        roleLabel: 'Pomocnik',
        ftpWatts: 385,
      ),
    ];
  }

  /// Oblicza ilu aktywnych kolarzy obejmą kroki makra.
  static int countAffectedRiders(
    QuickTacticalMacro macro,
    List<MacroTeamRiderSlot> roster,
  ) {
    final activeRoster = roster.where((r) => r.isActive).toList();
    if (activeRoster.isEmpty || macro.steps.isEmpty) return 0;
    final Set<String> affectedIds = {};
    for (final step in macro.steps) {
      if (step.targetId == MacroTargetScope.allTeam) {
        affectedIds.addAll(activeRoster.map((r) => r.id));
      } else if (step.targetId == MacroTargetScope.leadersOnly) {
        affectedIds.addAll(activeRoster.where((r) => r.isLeader).map((r) => r.id));
      } else if (step.targetId == MacroTargetScope.domestiquesOnly) {
        affectedIds.addAll(activeRoster.where((r) => !r.isLeader).map((r) => r.id));
      } else {
        if (activeRoster.any((r) => r.id == step.targetId)) {
          affectedIds.add(step.targetId);
        }
      }
    }
    return affectedIds.length;
  }

  /// Waliduje makro przed zapisem. Zwraca komunikat błędu lub `null`, gdy poprawne.
  static String? validateMacro({
    required String name,
    required List<TacticalMacroStep> steps,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return 'Podaj nazwę makra taktycznego.';
    }
    if (trimmed.length > 48) {
      return 'Nazwa makra może mieć maksymalnie 48 znaków.';
    }
    if (steps.isEmpty) {
      return 'Nagraj przynajmniej jeden krok rozkazu dla drużyny.';
    }
    return null;
  }

  static String exportMacrosToJson(List<QuickTacticalMacro> macros) {
    return const JsonEncoder.withIndent('  ')
        .convert(macros.map((m) => m.toJson()).toList());
  }

  static List<QuickTacticalMacro> importMacrosFromJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! List) {
      throw const FormatException('Oczekiwano tablicy JSON makr taktycznych.');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(QuickTacticalMacro.fromJson)
        .toList();
  }
}

/// Produkcyjny widget nagrywarki i szybkiego odtwarzacza makr taktycznych dla całej drużyny.
///
/// Obsługuje:
/// - uruchamianie zapisanych makr jednym kliknięciem (1-Click Team Macro),
/// - nagrywanie sekwencji rozkazów taktycznych w czasie rzeczywistym (REC / PAUSE / STOP),
/// - podgląd i edycję nagranych kroków,
/// - filtrowanie po kategoriach oraz responsywny układ `390x844`, `1024x768`, `1600x900`.
class QuickTacticalMacroRecorderWidget extends StatefulWidget {
  final List<MacroTeamRiderSlot> roster;
  final List<QuickTacticalMacro>? initialMacros;
  final bool enabled;
  final ValueChanged<MacroExecutionResult>? onExecuteMacro;
  final ValueChanged<TacticalMacroStep>? onApplyStep;
  final ValueChanged<List<QuickTacticalMacro>>? onMacrosChanged;

  const QuickTacticalMacroRecorderWidget({
    super.key,
    required this.roster,
    this.initialMacros,
    this.enabled = true,
    this.onExecuteMacro,
    this.onApplyStep,
    this.onMacrosChanged,
  });

  @override
  State<QuickTacticalMacroRecorderWidget> createState() =>
      _QuickTacticalMacroRecorderWidgetState();
}

class _QuickTacticalMacroRecorderWidgetState
    extends State<QuickTacticalMacroRecorderWidget>
    with SingleTickerProviderStateMixin {
  late List<QuickTacticalMacro> _macros;
  String? _selectedMacroId;
  TacticalMacroCategory? _categoryFilter;

  MacroRecorderPhase _phase = MacroRecorderPhase.idle;
  int _elapsedRecordMs = 0;
  Timer? _recordTimer;
  Timer? _playbackTimer;
  int _playbackStepCursor = -1;

  // Bieżące parametry przechwytywania kroku podczas nagrywania
  final List<TacticalMacroStep> _draftSteps = [];
  String _selectedTargetId = MacroTargetScope.allTeam;
  TacticalOrder _selectedOrder = TacticalOrder.pullGroup;
  double _selectedEffortPercent = 95.0;
  MacroTriggerCondition _selectedTrigger = MacroTriggerCondition.immediate;
  TacticalMacroCategory _draftCategory = TacticalMacroCategory.custom;

  final TextEditingController _macroNameController = TextEditingController();
  final TextEditingController _hotkeyController = TextEditingController(text: 'M5');
  String? _validationError;
  String? _statusBanner;
  bool _statusIsError = false;

  late final AnimationController _recPulseController;

  @override
  void initState() {
    super.initState();
    _macros = List<QuickTacticalMacro>.from(
      widget.initialMacros ?? QuickTacticalMacroManager.defaultTeamMacros(),
    );
    if (_macros.isNotEmpty) {
      _selectedMacroId = _macros.first.id;
    }
    _recPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playbackTimer?.cancel();
    _recPulseController.dispose();
    _macroNameController.dispose();
    _hotkeyController.dispose();
    super.dispose();
  }

  QuickTacticalMacro? get _selectedMacro {
    if (_selectedMacroId == null) return null;
    for (final macro in _macros) {
      if (macro.id == _selectedMacroId) return macro;
    }
    return _macros.isNotEmpty ? _macros.first : null;
  }

  List<QuickTacticalMacro> get _filteredMacros {
    if (_categoryFilter == null) return _macros;
    return _macros.where((m) => m.category == _categoryFilter).toList();
  }

  bool get _hasActiveRiders => widget.roster.any((r) => r.isActive);

  void _setStatus(String message, {bool isError = false}) {
    setState(() {
      _statusBanner = message;
      _statusIsError = isError;
    });
  }

  void _startRecording() {
    if (!widget.enabled || !_hasActiveRiders) return;
    _playbackTimer?.cancel();
    _recordTimer?.cancel();
    setState(() {
      _phase = MacroRecorderPhase.recording;
      _elapsedRecordMs = 0;
      _draftSteps.clear();
      _validationError = null;
      _statusBanner = 'Nagrywanie aktywne — wydawaj rozkazy, aby zapisać sekwencję.';
      _statusIsError = false;
    });
    _recPulseController.repeat(reverse: true);
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_phase == MacroRecorderPhase.recording) {
        setState(() {
          _elapsedRecordMs += 100;
        });
      }
    });
  }

  void _togglePauseRecording() {
    if (!widget.enabled) return;
    if (_phase == MacroRecorderPhase.recording) {
      _recPulseController.stop();
      setState(() {
        _phase = MacroRecorderPhase.paused;
        _statusBanner = 'Nagrywanie wstrzymane.';
        _statusIsError = false;
      });
    } else if (_phase == MacroRecorderPhase.paused) {
      _recPulseController.repeat(reverse: true);
      setState(() {
        _phase = MacroRecorderPhase.recording;
        _statusBanner = 'Wznowiono nagrywanie makra.';
        _statusIsError = false;
      });
    }
  }

  void _discardRecording() {
    _recordTimer?.cancel();
    _recPulseController.stop();
    _recPulseController.reset();
    setState(() {
      _phase = MacroRecorderPhase.idle;
      _elapsedRecordMs = 0;
      _draftSteps.clear();
      _validationError = null;
      _statusBanner = 'Anulowano bieżące nagranie.';
      _statusIsError = false;
    });
  }

  void _captureStep([TacticalOrder? overrideOrder]) {
    if (!widget.enabled ||
        (_phase != MacroRecorderPhase.recording &&
            _phase != MacroRecorderPhase.paused)) {
      return;
    }
    final orderToUse = overrideOrder ?? _selectedOrder;
    MacroTeamRiderSlot? matchedRider;
    for (final r in widget.roster) {
      if (r.id == _selectedTargetId) {
        matchedRider = r;
        break;
      }
    }

    final targetLabel =
        MacroTargetScope.labelFor(_selectedTargetId, matchedRider?.name);
    final newStep = TacticalMacroStep(
      id: 'step_${DateTime.now().microsecondsSinceEpoch}_${_draftSteps.length}',
      stepIndex: _draftSteps.length,
      targetId: _selectedTargetId,
      targetLabel: targetLabel,
      bibNumber: matchedRider?.bibNumber,
      order: orderToUse,
      targetEffortPercent: _selectedEffortPercent,
      offsetMilliseconds: _elapsedRecordMs,
      triggerCondition: _elapsedRecordMs > 0 && _selectedTrigger == MacroTriggerCondition.immediate
          ? MacroTriggerCondition.afterDelay
          : _selectedTrigger,
      note: '${orderToUse.label} (${_selectedEffortPercent.round()}% FTP)',
    );

    setState(() {
      _selectedOrder = orderToUse;
      _draftSteps.add(newStep);
      _validationError = null;
      _statusBanner =
          'Dodano krok #${_draftSteps.length}: $targetLabel → ${orderToUse.label}';
      _statusIsError = false;
    });
  }

  void _removeDraftStep(int index) {
    if (index < 0 || index >= _draftSteps.length) return;
    setState(() {
      _draftSteps.removeAt(index);
      for (int i = 0; i < _draftSteps.length; i++) {
        _draftSteps[i] = _draftSteps[i].copyWith(stepIndex: i);
      }
    });
  }

  void _saveRecordedMacro() {
    if (!widget.enabled) return;
    final defaultName = _macroNameController.text.trim().isEmpty
        ? 'Taktyka #${_macros.length + 1}'
        : _macroNameController.text.trim();
    final error = QuickTacticalMacroManager.validateMacro(
      name: defaultName,
      steps: _draftSteps,
    );
    if (error != null) {
      setState(() {
        _validationError = error;
      });
      return;
    }

    _recordTimer?.cancel();
    _recPulseController.stop();
    _recPulseController.reset();

    final newMacro = QuickTacticalMacro(
      id: 'macro_${DateTime.now().microsecondsSinceEpoch}',
      name: defaultName,
      hotkeyLabel: _hotkeyController.text.trim().isEmpty
          ? null
          : _hotkeyController.text.trim().toUpperCase(),
      category: _draftCategory,
      steps: List<TacticalMacroStep>.from(_draftSteps),
      createdAt: DateTime.now(),
      isPinned: true,
    );

    setState(() {
      _macros.insert(0, newMacro);
      _selectedMacroId = newMacro.id;
      _phase = MacroRecorderPhase.idle;
      _elapsedRecordMs = 0;
      _draftSteps.clear();
      _macroNameController.clear();
      _validationError = null;
      _statusBanner = 'Zapisano makro "${newMacro.name}" (${newMacro.steps.length} kroków).';
      _statusIsError = false;
    });
    widget.onMacrosChanged?.call(List.unmodifiable(_macros));
  }

  void _executeMacroOneClick(QuickTacticalMacro macro) {
    if (!widget.enabled || !_hasActiveRiders || macro.steps.isEmpty) return;
    _playbackTimer?.cancel();

    final affectedCount =
        QuickTacticalMacroManager.countAffectedRiders(macro, widget.roster);

    final updatedMacro = macro.copyWith(
      executionCount: macro.executionCount + 1,
    );
    final idx = _macros.indexWhere((m) => m.id == macro.id);
    if (idx != -1) {
      _macros[idx] = updatedMacro;
    }

    for (final step in macro.steps) {
      widget.onApplyStep?.call(step);
    }

    final result = MacroExecutionResult(
      macro: updatedMacro,
      executedSteps: List.unmodifiable(macro.steps),
      affectedRidersCount: affectedCount,
      executedAt: DateTime.now(),
      radioBroadcast:
          'Radio DS: Odpalono makro "${macro.name}" — $affectedCount kolarzy wykonuje ${macro.steps.length} rozkazów.',
    );
    widget.onExecuteMacro?.call(result);
    widget.onMacrosChanged?.call(List.unmodifiable(_macros));

    setState(() {
      _selectedMacroId = updatedMacro.id;
      _phase = MacroRecorderPhase.playback;
      _playbackStepCursor = 0;
      _statusBanner = result.radioBroadcast;
      _statusIsError = false;
    });

    int cursor = 0;
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 280), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      cursor++;
      if (cursor >= macro.steps.length) {
        timer.cancel();
        setState(() {
          _phase = MacroRecorderPhase.idle;
          _playbackStepCursor = -1;
        });
      } else {
        setState(() {
          _playbackStepCursor = cursor;
        });
      }
    });
  }

  void _deleteMacro(QuickTacticalMacro macro) {
    if (!widget.enabled) return;
    setState(() {
      _macros.removeWhere((m) => m.id == macro.id);
      if (_selectedMacroId == macro.id) {
        _selectedMacroId = _macros.isNotEmpty ? _macros.first.id : null;
      }
      _statusBanner = 'Usunięto makro "${macro.name}".';
      _statusIsError = false;
    });
    widget.onMacrosChanged?.call(List.unmodifiable(_macros));
  }

  void _togglePinMacro(QuickTacticalMacro macro) {
    if (!widget.enabled) return;
    final idx = _macros.indexWhere((m) => m.id == macro.id);
    if (idx == -1) return;
    setState(() {
      _macros[idx] = macro.copyWith(isPinned: !macro.isPinned);
    });
    widget.onMacrosChanged?.call(List.unmodifiable(_macros));
  }

  Future<void> _copyJsonToClipboard() async {
    if (_macros.isEmpty) return;
    final jsonStr = QuickTacticalMacroManager.exportMacrosToJson(_macros);
    await Clipboard.setData(ClipboardData(text: jsonStr));
    if (!mounted) return;
    _setStatus('Skopiowano ${_macros.length} makr do schowka (JSON).');
  }

  String _formatElapsed(int ms) {
    final totalSeconds = ms ~/ 1000;
    final tenths = (ms % 1000) ~/ 100;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds.$tenths';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final isCompact = width < 720;
        final isWide = width >= 1100;

        return Opacity(
          opacity: widget.enabled ? 1.0 : 0.58,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _phase == MacroRecorderPhase.recording
                    ? AppColors.crimsonAlert.withValues(alpha: 0.75)
                    : AppTheme.borderColor,
                width: 1.0,
              ),
            ),
            padding: EdgeInsets.all(isCompact ? 12 : 18),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(isCompact),
                  if (_statusBanner != null) ...[
                    const SizedBox(height: 10),
                    _buildStatusBanner(),
                  ],
                  const SizedBox(height: 14),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildLeftColumn(isCompact: false),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 5,
                          child: _buildRightColumn(isCompact: false),
                        ),
                      ],
                    )
                  else ...[
                    _buildLeftColumn(isCompact: isCompact),
                    const SizedBox(height: 16),
                    _buildRightColumn(isCompact: isCompact),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final isRecording = _phase == MacroRecorderPhase.recording;
    final isPaused = _phase == MacroRecorderPhase.paused;
    final activeRosterCount = widget.roster.where((r) => r.isActive).length;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
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
                color: isRecording
                    ? AppColors.crimsonAlert.withValues(alpha: 0.18)
                    : AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRecording
                      ? AppColors.crimsonAlert
                      : AppColors.primaryAccent,
                ),
              ),
              child: Icon(
                isRecording
                    ? Icons.fiber_manual_record_rounded
                    : Icons.bolt_rounded,
                color: isRecording
                    ? AppColors.crimsonAlert
                    : AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nagrywarka Makr Taktycznych',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isCompact ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Jednym przyciskiem dla drużyny • Aktywni kolarze: $activeRosterCount/${widget.roster.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (isRecording || isPaused)
              AnimatedBuilder(
                animation: _recPulseController,
                builder: (context, child) {
                  final pulseAlpha = isRecording
                      ? 0.45 + 0.55 * _recPulseController.value
                      : 0.65;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.crimsonAlert.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.crimsonAlert.withValues(alpha: pulseAlpha),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRecording ? Icons.circle : Icons.pause_circle_filled,
                          size: 10,
                          color: isRecording
                              ? AppColors.crimsonAlert
                              : AppColors.amberWarning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${isRecording ? "REC" : "PAUZA"} ${_formatElapsed(_elapsedRecordMs)}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            _MacroActionButton(
              label: isRecording || isPaused ? 'Anuluj REC' : 'Nagraj Makro',
              icon: isRecording || isPaused
                  ? Icons.close_rounded
                  : Icons.fiber_manual_record_rounded,
              accentColor: isRecording || isPaused
                  ? AppColors.textSecondary
                  : AppColors.crimsonAlert,
              filled: !(isRecording || isPaused),
              enabled: widget.enabled && _hasActiveRiders,
              onPressed: isRecording || isPaused ? _discardRecording : _startRecording,
            ),
            if (isRecording || isPaused)
              _MacroActionButton(
                label: isRecording ? 'Pauza' : 'Wznów',
                icon: isRecording ? Icons.pause_rounded : Icons.play_arrow_rounded,
                accentColor: AppColors.amberWarning,
                enabled: widget.enabled,
                onPressed: _togglePauseRecording,
              ),
            _MacroActionButton(
              label: 'Eksport JSON',
              icon: Icons.data_object_rounded,
              accentColor: AppColors.accentBlue,
              enabled: widget.enabled && _macros.isNotEmpty,
              onPressed: _copyJsonToClipboard,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    final color = _statusIsError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(
            _statusIsError ? Icons.error_outline_rounded : Icons.campaign_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _statusBanner!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _statusBanner = null),
            icon: const Icon(Icons.close, size: 15, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: 'Zamknij powiadomienie',
          ),
        ],
      ),
    );
  }

  Widget _buildLeftColumn({required bool isCompact}) {
    final isRecordingMode =
        _phase == MacroRecorderPhase.recording || _phase == MacroRecorderPhase.paused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isRecordingMode) ...[
          _buildLiveRecorderDeck(isCompact),
          const SizedBox(height: 14),
        ],
        _buildOneClickMacroDeck(isCompact),
      ],
    );
  }

  Widget _buildLiveRecorderDeck(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.65)),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.radio_button_checked,
                  color: AppColors.crimsonAlert, size: 16),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Studio Przechwytywania Kroków',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                'Kroki: ${_draftSteps.length}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Cel rozkazu (drużyna / rola / kolarz)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _SelectableChip(
                label: 'Cała drużyna',
                icon: Icons.groups_rounded,
                selected: _selectedTargetId == MacroTargetScope.allTeam,
                accentColor: AppColors.goldAccent,
                enabled: widget.enabled,
                onTap: () =>
                    setState(() => _selectedTargetId = MacroTargetScope.allTeam),
              ),
              _SelectableChip(
                label: 'Liderzy',
                icon: Icons.star_rounded,
                selected: _selectedTargetId == MacroTargetScope.leadersOnly,
                accentColor: AppColors.goldAccent,
                enabled: widget.enabled,
                onTap: () =>
                    setState(() => _selectedTargetId = MacroTargetScope.leadersOnly),
              ),
              _SelectableChip(
                label: 'Pomocnicy',
                icon: Icons.shield_outlined,
                selected: _selectedTargetId == MacroTargetScope.domestiquesOnly,
                accentColor: AppColors.accentBlue,
                enabled: widget.enabled,
                onTap: () => setState(
                    () => _selectedTargetId = MacroTargetScope.domestiquesOnly),
              ),
              ...widget.roster.where((r) => r.isActive).map(
                    (rider) => _SelectableChip(
                      label: '#${rider.bibNumber} ${rider.name}',
                      selected: _selectedTargetId == rider.id,
                      accentColor: AppColors.cyanAccent,
                      enabled: widget.enabled,
                      onTap: () => setState(() => _selectedTargetId = rider.id),
                    ),
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. Intensywność (% FTP)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_selectedEffortPercent.round()}% FTP',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _effortColor(_selectedEffortPercent),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _effortColor(_selectedEffortPercent),
              inactiveTrackColor: AppColors.cardBorder,
              thumbColor: AppColors.textPrimary,
              overlayColor:
                  _effortColor(_selectedEffortPercent).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _selectedEffortPercent,
              min: 50,
              max: 120,
              divisions: 14,
              onChanged: widget.enabled
                  ? (v) => setState(() => _selectedEffortPercent = v)
                  : null,
            ),
          ),
          const Text(
            '3. Warunek wyzwolenia kroku',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: MacroTriggerCondition.values.map((cond) {
              return _SelectableChip(
                label: cond.label,
                selected: _selectedTrigger == cond,
                accentColor: AppColors.accentBlue,
                enabled: widget.enabled,
                onTap: () => setState(() => _selectedTrigger = cond),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Text(
            '4. Kliknij rozkaz, aby natychmiast nagrać krok',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: TacticalOrder.values.map((order) {
              return _SelectableChip(
                label: order.label,
                icon: _orderIcon(order),
                selected: _selectedOrder == order,
                accentColor: _orderColor(order),
                enabled: widget.enabled,
                onTap: () => _captureStep(order),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isCompact ? double.infinity : 210,
                child: TextField(
                  controller: _macroNameController,
                  enabled: widget.enabled,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nazwa makra',
                    hintText: 'np. Pociąg pod górę',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.goldAccent),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 82,
                child: TextField(
                  controller: _hotkeyController,
                  enabled: widget.enabled,
                  maxLength: 4,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Skrót',
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: AppColors.background,
                    labelStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: DropdownButton<TacticalMacroCategory>(
                    value: _draftCategory,
                    dropdownColor: AppColors.surfaceLight,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                    items: TacticalMacroCategory.values
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.label),
                          ),
                        )
                        .toList(),
                    onChanged: widget.enabled
                        ? (val) {
                            if (val != null) setState(() => _draftCategory = val);
                          }
                        : null,
                  ),
                ),
              ),
              _MacroActionButton(
                label: 'Zapisz Makro',
                icon: Icons.save_rounded,
                accentColor: AppColors.statusSuccess,
                filled: true,
                enabled: widget.enabled && _draftSteps.isNotEmpty,
                onPressed: _saveRecordedMacro,
              ),
            ],
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationError!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.crimsonAlert,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOneClickMacroDeck(bool isCompact) {
    final filtered = _filteredMacros;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.playlist_play_rounded,
                  color: AppColors.goldAccent, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Makra Drużyny (1-Click)',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${filtered.length} pozycji',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SelectableChip(
                  label: 'Wszystkie',
                  selected: _categoryFilter == null,
                  accentColor: AppColors.goldAccent,
                  enabled: widget.enabled,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: 6),
                ...TacticalMacroCategory.values.map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _SelectableChip(
                      label: cat.label,
                      icon: cat.icon,
                      selected: _categoryFilter == cat,
                      accentColor: cat.accentColor,
                      enabled: widget.enabled,
                      onTap: () => setState(() => _categoryFilter = cat),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(Icons.layers_clear_rounded,
                      color: AppColors.textSecondary, size: 28),
                  SizedBox(height: 8),
                  Text(
                    'Brak zapisanych makr w tej kategorii',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kliknij "Nagraj Makro", aby zarejestrować nową sekwencję rozkazów.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filtered.map(
              (macro) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MacroDeckTile(
                  macro: macro,
                  isSelected: _selectedMacro?.id == macro.id,
                  isPlaying: _phase == MacroRecorderPhase.playback &&
                      _selectedMacro?.id == macro.id,
                  affectedCount: QuickTacticalMacroManager.countAffectedRiders(
                    macro,
                    widget.roster,
                  ),
                  enabled: widget.enabled && _hasActiveRiders,
                  onSelect: () => setState(() => _selectedMacroId = macro.id),
                  onExecute: () => _executeMacroOneClick(macro),
                  onTogglePin: () => _togglePinMacro(macro),
                  onDelete: () => _deleteMacro(macro),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRightColumn({required bool isCompact}) {
    final isRecordingMode =
        _phase == MacroRecorderPhase.recording || _phase == MacroRecorderPhase.paused;
    final selectedMacro = _selectedMacro;
    final stepsToShow =
        isRecordingMode ? _draftSteps : (selectedMacro?.steps ?? const []);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isRecordingMode
                    ? Icons.timeline_rounded
                    : Icons.format_list_numbered_rounded,
                color: AppColors.accentBlue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRecordingMode
                      ? 'Podgląd Nagrania (${_draftSteps.length})'
                      : (selectedMacro != null
                          ? 'Sekwencja: ${selectedMacro.name}'
                          : 'Sekwencja Kroków'),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!isRecordingMode && selectedMacro != null)
                _MacroActionButton(
                  label: 'Odpal',
                  icon: Icons.play_arrow_rounded,
                  accentColor: selectedMacro.category.accentColor,
                  filled: true,
                  enabled: widget.enabled && _hasActiveRiders,
                  onPressed: () => _executeMacroOneClick(selectedMacro),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (stepsToShow.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                isRecordingMode
                    ? 'Wybierz cel i kliknij dowolny rozkaz taktyczny po lewej stronie, aby zarejestrować pierwszy krok.'
                    : 'Wybierz makro z listy, aby podejrzeć lub uruchomić jego kroki.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...List.generate(stepsToShow.length, (idx) {
              final step = stepsToShow[idx];
              final isHighlighted = _phase == MacroRecorderPhase.playback &&
                  _playbackStepCursor == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MacroStepRow(
                  step: step,
                  isHighlighted: isHighlighted,
                  canDelete: isRecordingMode && widget.enabled,
                  onDelete: () => _removeDraftStep(idx),
                ),
              );
            }),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 10),
          const Text(
            'Skład Drużyny na Etapie',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.roster.isEmpty)
            const Text(
              'Brak kolarzy przypisanych do etapu.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            )
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.roster.map((rider) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: rider.isActive
                        ? AppColors.surface
                        : AppColors.surface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: rider.isLeader
                          ? AppColors.goldAccent.withValues(alpha: 0.5)
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${rider.bibNumber}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rider.isLeader
                              ? AppColors.goldAccent
                              : AppColors.textSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rider.name,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: rider.isActive
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          decoration: rider.isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  static Color _effortColor(double percent) {
    if (percent >= 105) return AppColors.crimsonAlert;
    if (percent >= 92) return AppColors.powerZone5;
    if (percent >= 80) return AppColors.goldAccent;
    return AppColors.statusSuccess;
  }

  static IconData _orderIcon(TacticalOrder order) {
    switch (order) {
      case TacticalOrder.holdPosition:
        return Icons.drag_handle_rounded;
      case TacticalOrder.pullGroup:
        return Icons.speed_rounded;
      case TacticalOrder.protectLeader:
        return Icons.shield_rounded;
      case TacticalOrder.attack:
        return Icons.flash_on_rounded;
      case TacticalOrder.followWheels:
        return Icons.link_rounded;
      case TacticalOrder.fetchBidonsFromCar:
        return Icons.local_drink_rounded;
      case TacticalOrder.saveEnergy:
        return Icons.battery_saver_rounded;
    }
  }

  static Color _orderColor(TacticalOrder order) {
    switch (order) {
      case TacticalOrder.holdPosition:
        return AppColors.accentBlue;
      case TacticalOrder.pullGroup:
        return AppColors.powerZone5;
      case TacticalOrder.protectLeader:
        return AppColors.goldAccent;
      case TacticalOrder.attack:
        return AppColors.crimsonAlert;
      case TacticalOrder.followWheels:
        return AppColors.cyanAccent;
      case TacticalOrder.fetchBidonsFromCar:
        return AppColors.powerZone2;
      case TacticalOrder.saveEnergy:
        return AppColors.statusSuccess;
    }
  }
}

class _MacroDeckTile extends StatefulWidget {
  final QuickTacticalMacro macro;
  final bool isSelected;
  final bool isPlaying;
  final int affectedCount;
  final bool enabled;
  final VoidCallback onSelect;
  final VoidCallback onExecute;
  final VoidCallback onTogglePin;
  final VoidCallback onDelete;

  const _MacroDeckTile({
    required this.macro,
    required this.isSelected,
    required this.isPlaying,
    required this.affectedCount,
    required this.enabled,
    required this.onSelect,
    required this.onExecute,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  State<_MacroDeckTile> createState() => _MacroDeckTileState();
}

class _MacroDeckTileState extends State<_MacroDeckTile> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.macro.category.accentColor;
    final borderColor = widget.isPlaying
        ? AppColors.statusSuccess
        : (_focused
            ? AppColors.goldAccent
            : (widget.isSelected || _hovered
                ? accent.withValues(alpha: 0.75)
                : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppColors.surfaceLight
              : (_hovered
                  ? AppColors.surfaceLight.withValues(alpha: 0.65)
                  : AppColors.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: widget.isSelected ? 1.4 : 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.enabled ? widget.onSelect : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: Icon(widget.macro.category.icon, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.macro.hotkeyLabel != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Text(
                                widget.macro.hotkeyLabel!,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.goldAccent,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              widget.macro.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.macro.steps.length} kroków • ${widget.affectedCount} kolarzy • Użyto: ${widget.macro.executionCount}x',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.enabled ? widget.onTogglePin : null,
                  icon: Icon(
                    widget.macro.isPinned
                        ? Icons.push_pin_rounded
                        : Icons.push_pin_outlined,
                    size: 16,
                    color: widget.macro.isPinned
                        ? AppColors.goldAccent
                        : AppColors.textSecondary,
                  ),
                  tooltip: widget.macro.isPinned ? 'Odepnij' : 'Przypnij',
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  onPressed: widget.enabled ? widget.onDelete : null,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  tooltip: 'Usuń makro',
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 4),
                _MacroActionButton(
                  label: widget.isPlaying ? 'Aktywne' : 'Odpal',
                  icon: widget.isPlaying
                      ? Icons.graphic_eq_rounded
                      : Icons.play_arrow_rounded,
                  accentColor:
                      widget.isPlaying ? AppColors.statusSuccess : accent,
                  filled: true,
                  compact: true,
                  enabled: widget.enabled,
                  onPressed: widget.onExecute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroStepRow extends StatelessWidget {
  final TacticalMacroStep step;
  final bool isHighlighted;
  final bool canDelete;
  final VoidCallback onDelete;

  const _MacroStepRow({
    required this.step,
    required this.isHighlighted,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final secondsText = '+${(step.offsetMilliseconds / 1000).toStringAsFixed(1)}s';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.statusSuccess.withValues(alpha: 0.16)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.statusSuccess : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${step.stepIndex + 1}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.goldAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${step.targetLabel} • ${step.order.label}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$secondsText • ${step.targetEffortPercent.round()}% FTP • ${step.triggerCondition.label}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.crimsonAlert),
              tooltip: 'Usuń krok',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            ),
        ],
      ),
    );
  }
}

class _SelectableChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color accentColor;
  final bool enabled;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.accentColor,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_SelectableChip> createState() => _SelectableChipState();
}

class _SelectableChipState extends State<_SelectableChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? widget.accentColor.withValues(alpha: 0.22)
        : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final border = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? widget.accentColor
            : (_hovered
                ? widget.accentColor.withValues(alpha: 0.55)
                : AppColors.cardBorder));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: widget.enabled ? widget.onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 13,
                    color: widget.selected
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                    color: widget.selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool filled;
  final bool compact;
  final bool enabled;
  final VoidCallback onPressed;

  const _MacroActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.filled = false,
    this.compact = false,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_MacroActionButton> createState() => _MacroActionButtonState();
}

class _MacroActionButtonState extends State<_MacroActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseAlpha = widget.filled ? 0.24 : 0.12;
    final hoverAlpha = widget.filled ? 0.36 : 0.22;
    final bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : widget.accentColor.withValues(alpha: _hovered ? hoverAlpha : baseAlpha);

    final borderColor = !widget.enabled
        ? AppColors.cardBorder
        : (_focused
            ? AppColors.goldAccent
            : widget.accentColor.withValues(alpha: _hovered ? 0.95 : 0.65));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: AnimatedScale(
        scale: _pressed && widget.enabled ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.enabled ? widget.onPressed : null,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 9 : 11,
                vertical: widget.compact ? 6 : 8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.icon,
                    size: widget.compact ? 14 : 15,
                    color: widget.enabled
                        ? widget.accentColor
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: widget.compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
