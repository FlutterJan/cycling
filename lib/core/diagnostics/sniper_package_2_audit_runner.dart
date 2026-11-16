// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Kategoria elementu w manifeście Paczki #2 (#213–#262).
enum Package2TaskCategory {
  physics('Fizyka i Fizjologia', Icons.speed_rounded),
  pelotonAi('Taktyka i AI Peletonu', Icons.groups_rounded),
  engine3d('Silnik 3D 120 FPS', Icons.view_in_ar_rounded),
  simulation('Symulacja', Icons.memory_rounded),
  service('Serwis Kariery i Bazy', Icons.miscellaneous_services_rounded),
  uiWidget('Widget UI / HUD', Icons.widgets_rounded),
  uiScreen('Ekran UI', Icons.desktop_windows_rounded),
  testSuite('Testy Regresji', Icons.verified_rounded),
  diagnostics('Diagnostyka', Icons.health_and_safety_rounded);

  final String label;
  final IconData icon;

  const Package2TaskCategory(this.label, this.icon);
}

/// Poziom ważności wykrytego problemu w audycie Paczki #2.
enum Package2AuditSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const Package2AuditSeverity(this.label, this.color);
}

/// Definicja pojedynczego zadania z Paczki #2 (#213–#262).
@immutable
class Package2TaskSpec {
  final int taskNumber;
  final String filePath;
  final List<String> primarySymbols;
  final Package2TaskCategory category;
  final String description;
  final bool requiresResponsiveLayout;

  const Package2TaskSpec({
    required this.taskNumber,
    required this.filePath,
    required this.primarySymbols,
    required this.category,
    required this.description,
    this.requiresResponsiveLayout = false,
  });
}

/// Pojedynczy problem zgłoszony przez `flutter analyze`.
@immutable
class Package2AnalyzeIssue {
  final Package2AuditSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const Package2AnalyzeIssue({
    required this.severity,
    required this.message,
    required this.filePath,
    required this.line,
    required this.column,
    required this.ruleName,
  });

  Map<String, dynamic> toJson() => {
        'severity': severity.name,
        'message': message,
        'filePath': filePath,
        'line': line,
        'column': column,
        'ruleName': ruleName,
      };
}

/// Wynik uruchomienia `flutter analyze`.
@immutable
class Package2FlutterAnalyzeResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final List<Package2AnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const Package2FlutterAnalyzeResult({
    required this.executed,
    required this.exitCode,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.issues,
    required this.rawOutput,
    required this.duration,
  });

  bool get passed =>
      !executed || (exitCode == 0 && errorCount == 0 && warningCount == 0);

  factory Package2FlutterAnalyzeResult.skipped() =>
      const Package2FlutterAnalyzeResult(
        executed: false,
        exitCode: 0,
        errorCount: 0,
        warningCount: 0,
        infoCount: 0,
        issues: [],
        rawOutput: 'Pominięto analizę procesu flutter analyze.',
        duration: Duration.zero,
      );

  Map<String, dynamic> toJson() => {
        'executed': executed,
        'exitCode': exitCode,
        'errorCount': errorCount,
        'warningCount': warningCount,
        'infoCount': infoCount,
        'passed': passed,
        'durationMs': duration.inMilliseconds,
        'issues': issues.map((e) => e.toJson()).toList(),
      };
}

/// Wynik audytu kompletności pliku `docs/CODE_MAP.md` dla Paczki #2.
@immutable
class Package2CodeMapAuditResult {
  final bool codeMapExists;
  final int totalLines;
  final int package2CoveredCount;
  final List<String> missingFilePaths;
  final Map<String, List<String>> missingSymbolsByFile;

  const Package2CodeMapAuditResult({
    required this.codeMapExists,
    required this.totalLines,
    required this.package2CoveredCount,
    required this.missingFilePaths,
    required this.missingSymbolsByFile,
  });

  bool get passed =>
      codeMapExists && missingFilePaths.isEmpty && missingSymbolsByFile.isEmpty;

  Map<String, dynamic> toJson() => {
        'codeMapExists': codeMapExists,
        'totalLines': totalLines,
        'package2CoveredCount': package2CoveredCount,
        'missingFilePaths': missingFilePaths,
        'missingSymbolsByFile': missingSymbolsByFile,
        'passed': passed,
      };
}

/// Wynik audytu integracji Paczki #2 z resztą gry (mosty, importy, referencje).
@immutable
class Package2IntegrationCheckResult {
  final int totalScannedLibFiles;
  final int totalScannedTestFiles;
  final List<String> verifiedCoreBridges;
  final List<String> missingCoreBridges;
  final Map<String, List<String>> brokenRelativeImportsByFile;
  final int integratedTasksCount;
  final int totalIntegrableTasksCount;

  const Package2IntegrationCheckResult({
    required this.totalScannedLibFiles,
    required this.totalScannedTestFiles,
    required this.verifiedCoreBridges,
    required this.missingCoreBridges,
    required this.brokenRelativeImportsByFile,
    required this.integratedTasksCount,
    required this.totalIntegrableTasksCount,
  });

  bool get passed =>
      missingCoreBridges.isEmpty && brokenRelativeImportsByFile.isEmpty;

  Map<String, dynamic> toJson() => {
        'totalScannedLibFiles': totalScannedLibFiles,
        'totalScannedTestFiles': totalScannedTestFiles,
        'verifiedCoreBridges': verifiedCoreBridges,
        'missingCoreBridges': missingCoreBridges,
        'brokenRelativeImportsByFile': brokenRelativeImportsByFile,
        'integratedTasksCount': integratedTasksCount,
        'totalIntegrableTasksCount': totalIntegrableTasksCount,
        'passed': passed,
      };
}

/// Szczegółowy wynik audytu pojedynczego zadania z Paczki #2.
@immutable
class Package2TaskAuditResult {
  final Package2TaskSpec spec;
  final bool fileExists;
  final int fileSizeBytes;
  final int lineCount;
  final List<String> presentSymbols;
  final List<String> missingSymbols;
  final int todoMarkersCount;
  final int unimplementedThrowsCount;
  final bool inCodeMap;
  final List<String> missingSymbolsInCodeMap;
  final bool hasResponsiveLayout;
  final bool usesAppColors;
  final List<String> brokenRelativeImports;
  final int libReferencesCount;
  final int testReferencesCount;
  final List<String> issues;

  const Package2TaskAuditResult({
    required this.spec,
    required this.fileExists,
    required this.fileSizeBytes,
    required this.lineCount,
    required this.presentSymbols,
    required this.missingSymbols,
    required this.todoMarkersCount,
    required this.unimplementedThrowsCount,
    required this.inCodeMap,
    required this.missingSymbolsInCodeMap,
    required this.hasResponsiveLayout,
    required this.usesAppColors,
    required this.brokenRelativeImports,
    required this.libReferencesCount,
    required this.testReferencesCount,
    required this.issues,
  });

  int get totalReferencesCount => libReferencesCount + testReferencesCount;

  bool get passed =>
      fileExists &&
      fileSizeBytes > 0 &&
      missingSymbols.isEmpty &&
      todoMarkersCount == 0 &&
      unimplementedThrowsCount == 0 &&
      inCodeMap &&
      brokenRelativeImports.isEmpty &&
      issues.isEmpty;

  Package2AuditSeverity get severity {
    if (!fileExists ||
        missingSymbols.isNotEmpty ||
        unimplementedThrowsCount > 0 ||
        brokenRelativeImports.isNotEmpty) {
      return Package2AuditSeverity.error;
    }
    if (!inCodeMap || todoMarkersCount > 0 || issues.isNotEmpty) {
      return Package2AuditSeverity.warning;
    }
    if (missingSymbolsInCodeMap.isNotEmpty) {
      return Package2AuditSeverity.info;
    }
    return Package2AuditSeverity.pass;
  }

  Map<String, dynamic> toJson() => {
        'taskNumber': spec.taskNumber,
        'filePath': spec.filePath,
        'fileExists': fileExists,
        'fileSizeBytes': fileSizeBytes,
        'lineCount': lineCount,
        'presentSymbols': presentSymbols,
        'missingSymbols': missingSymbols,
        'todoMarkersCount': todoMarkersCount,
        'unimplementedThrowsCount': unimplementedThrowsCount,
        'inCodeMap': inCodeMap,
        'missingSymbolsInCodeMap': missingSymbolsInCodeMap,
        'hasResponsiveLayout': hasResponsiveLayout,
        'usesAppColors': usesAppColors,
        'brokenRelativeImports': brokenRelativeImports,
        'libReferencesCount': libReferencesCount,
        'testReferencesCount': testReferencesCount,
        'issues': issues,
        'passed': passed,
      };
}

/// Pełny raport audytu integracji i spójności Paczki #2 (#213–#262).
@immutable
class Package2AuditReport {
  final DateTime generatedAt;
  final String projectRoot;
  final List<Package2TaskAuditResult> taskResults;
  final Package2CodeMapAuditResult codeMapResult;
  final Package2IntegrationCheckResult integrationResult;
  final Package2FlutterAnalyzeResult analyzeResult;
  final Duration duration;

  const Package2AuditReport({
    required this.generatedAt,
    required this.projectRoot,
    required this.taskResults,
    required this.codeMapResult,
    required this.integrationResult,
    required this.analyzeResult,
    required this.duration,
  });

  int get totalTasks => taskResults.length;
  int get passedTasks => taskResults.where((r) => r.passed).length;
  int get failedTasks => totalTasks - passedTasks;
  bool get overallPassed =>
      failedTasks == 0 &&
      codeMapResult.passed &&
      integrationResult.passed &&
      analyzeResult.passed;

  String toMarkdownSummary() {
    final buffer = StringBuffer()
      ..writeln('# Raport Audytu Integracji Paczki #2 (#213–#262)')
      ..writeln('- **Data**: ${generatedAt.toIso8601String()}')
      ..writeln('- **Katalog projektu**: `$projectRoot`')
      ..writeln('- **Zadania spójne**: $passedTasks / $totalTasks')
      ..writeln(
        '- **Integracja z grą**: ${integrationResult.passed ? 'ZWERYFIKOWANA' : 'BRAKI (${integrationResult.missingCoreBridges.length} mostów)'} '
        '(${integrationResult.integratedTasksCount}/${integrationResult.totalIntegrableTasksCount} modułów z referencjami)',
      )
      ..writeln(
        '- **CODE_MAP.md**: ${codeMapResult.passed ? 'KOMPLETNA' : 'BRAKI (${codeMapResult.missingFilePaths.length} plików)'}',
      )
      ..writeln(
        '- **flutter analyze**: ${analyzeResult.executed ? (analyzeResult.passed ? 'CZYSTY (0 błędów, 0 ostrzeżeń)' : '${analyzeResult.errorCount} błędów, ${analyzeResult.warningCount} ostrzeżeń') : 'POMINIĘTO'}',
      )
      ..writeln('- **Czas audytu**: ${duration.inMilliseconds} ms');

    final failed = taskResults.where((r) => !r.passed).toList();
    if (failed.isNotEmpty) {
      buffer.writeln('\n## Wykryte niezgodności');
      for (final item in failed) {
        buffer.writeln(
          '- **#${item.spec.taskNumber}** (`${item.spec.filePath}`): ${item.issues.join('; ')}',
        );
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'projectRoot': projectRoot,
        'totalTasks': totalTasks,
        'passedTasks': passedTasks,
        'failedTasks': failedTasks,
        'overallPassed': overallPassed,
        'durationMs': duration.inMilliseconds,
        'codeMapResult': codeMapResult.toJson(),
        'integrationResult': integrationResult.toJson(),
        'analyzeResult': analyzeResult.toJson(),
        'taskResults': taskResults.map((e) => e.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Skrypt i silnik audytowy weryfikujący kompletną integrację Paczki #2 (#213–#262)
/// z resztą gry, kompletność `docs/CODE_MAP.md` oraz zero ostrzeżeń w `flutter analyze`.
class SniperPackage2AuditRunner {
  const SniperPackage2AuditRunner();

  /// Kluczowe punkty integracji w grze, z którymi łączą się moduły Paczki #2.
  static const List<String> coreIntegrationBridges = [
    'lib/engine/engine_integration_bridge.dart',
    'lib/services/career/race_day_pipeline_orchestrator.dart',
    'lib/engine/rendering3d/peloton_3d_canvas_engine.dart',
    'lib/engine/simulation/stage_simulation_loop.dart',
    'lib/ui/screens/main_shell_screen.dart',
    'lib/core/router/app_router.dart',
  ];

  /// Pełny manifest 50 zadań Paczki #2 (#213–#262).
  static const List<Package2TaskSpec> package2Manifest = [
    Package2TaskSpec(
      taskNumber: 213,
      filePath: 'lib/engine/physics/alpine_climb_benchmark_calibrator.dart',
      primarySymbols: ['AlpineClimbBenchmarkCalibrator'],
      category: Package2TaskCategory.physics,
      description: 'Kalibrator solvera fizyki wspinaczki na realnych podjazdach HC',
    ),
    Package2TaskSpec(
      taskNumber: 214,
      filePath: 'lib/engine/peloton/breakaway_vs_peloton_equilibrium_solver.dart',
      primarySymbols: ['BreakawayVsPelotonEquilibriumSolver'],
      category: Package2TaskCategory.pelotonAi,
      description: 'Solver równowagi ucieczek vs peletonu wg profilu trasy',
    ),
    Package2TaskSpec(
      taskNumber: 215,
      filePath: 'lib/engine/peloton/sprint_leadout_aerodynamic_slingshot.dart',
      primarySymbols: ['SprintLeadoutAerodynamicSlingshot'],
      category: Package2TaskCategory.pelotonAi,
      description: 'Efekt procy aerodynamicznej na ostatnich 250 m sprintu',
    ),
    Package2TaskSpec(
      taskNumber: 216,
      filePath: 'lib/engine/physics/grand_tour_third_week_fatigue_decay.dart',
      primarySymbols: ['GrandTourThirdWeekFatigueDecay'],
      category: Package2TaskCategory.physics,
      description: 'Model kumulacji zmęczenia 3. tygodnia Grand Touru (etapy 14–21)',
    ),
    Package2TaskSpec(
      taskNumber: 217,
      filePath: 'lib/engine/physics/high_altitude_hypoxia_calculator.dart',
      primarySymbols: ['HighAltitudeHypoxiaCalculator'],
      category: Package2TaskCategory.physics,
      description: 'Naukowy model hipoksji wysokogórskiej >2000 m n.p.m.',
    ),
    Package2TaskSpec(
      taskNumber: 218,
      filePath: 'lib/engine/peloton/satellite_rider_relay_tactics_engine.dart',
      primarySymbols: [
        'SatelliteRiderRelayTacticsEngine',
        'SatelliteRelayTacticsPanel',
      ],
      category: Package2TaskCategory.pelotonAi,
      description: 'Taktyka Stacji Przekaźnikowych i rozkaz Wait for GC Leader',
    ),
    Package2TaskSpec(
      taskNumber: 219,
      filePath: 'lib/engine/peloton/kom_polka_dot_hunter_ai_controller.dart',
      primarySymbols: ['KomPolkaDotHunterAiController'],
      category: Package2TaskCategory.pelotonAi,
      description: 'AI łowców koszulki w grochy na premiach Cat 2, Cat 1 i HC',
    ),
    Package2TaskSpec(
      taskNumber: 220,
      filePath: 'lib/engine/peloton/wheelsucking_and_bluffing_ai_logic.dart',
      primarySymbols: ['WheelsuckingAndBluffingAiLogic'],
      category: Package2TaskCategory.pelotonAi,
      description: 'Taktyka pasywnej jazdy na kole (Skip Pulls / Poker Face)',
    ),
    Package2TaskSpec(
      taskNumber: 221,
      filePath: 'lib/engine/peloton/domestique_road_blocking_mechanics.dart',
      primarySymbols: ['DomestiqueRoadBlockingMechanics'],
      category: Package2TaskCategory.pelotonAi,
      description: 'Blokowanie pogoni na wąskich drogach <4.5 m przy 65% FTP',
    ),
    Package2TaskSpec(
      taskNumber: 222,
      filePath: 'lib/engine/peloton/gc_time_gap_panic_threshold_ai.dart',
      primarySymbols: ['GcTimeGapPanicThresholdAi'],
      category: Package2TaskCategory.pelotonAi,
      description: 'Reakcja kryzysowa AI GC przy stracie rywala <4 min (88% FTP)',
    ),
    Package2TaskSpec(
      taskNumber: 223,
      filePath: 'lib/ui/widgets/interactive_pre_stage_tactical_board.dart',
      primarySymbols: ['InteractivePreStageTacticalBoard'],
      category: Package2TaskCategory.uiWidget,
      description: 'Interaktywny Stół Taktyczny przed etapem na profilu trasy',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 224,
      filePath: 'lib/ui/widgets/live_energy_expenditure_sparklines_hud.dart',
      primarySymbols: ['LiveEnergyExpenditureSparklinesHud'],
      category: Package2TaskCategory.uiWidget,
      description: 'Panel HUD mini-wykresów 60s mocy, tętna i prognozy bonka',
    ),
    Package2TaskSpec(
      taskNumber: 225,
      filePath: 'lib/ui/widgets/peloton_group_composition_analyzer_modal.dart',
      primarySymbols: ['PelotonGroupCompositionAnalyzerModal'],
      category: Package2TaskCategory.uiWidget,
      description: 'Modal analityczny składu grupy i udziału drużyn na trasie',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 226,
      filePath: 'lib/services/career/tv_exposure_and_media_value_tracker.dart',
      primarySymbols: ['TvExposureAndMediaValueTracker', 'TvExposureMediaValuePanel'],
      category: Package2TaskCategory.service,
      description: 'Śledzenie ekspozycji TV sponsora i ekwiwalentu w M EUR',
    ),
    Package2TaskSpec(
      taskNumber: 227,
      filePath: 'lib/services/career/sponsor_bonus_negotiation_events.dart',
      primarySymbols: ['SponsorBonusNegotiationEvents', 'SponsorBonusCallDialogWidget'],
      category: Package2TaskCategory.service,
      description: 'Nadzwyczajne premie sponsorskie CEO po wielkich sukcesach',
    ),
    Package2TaskSpec(
      taskNumber: 228,
      filePath: 'lib/services/career/agent_contract_clauses_engine.dart',
      primarySymbols: ['AgentContractClausesEngine', 'AgentContractClausesPanel'],
      category: Package2TaskCategory.service,
      description: 'Klauzule specjalne kontraktów (GT Leadership, Equipment Veto)',
    ),
    Package2TaskSpec(
      taskNumber: 229,
      filePath: 'lib/services/career/broken_promises_locker_room_revolt.dart',
      primarySymbols: ['BrokenPromisesLockerRoomRevolt', 'BrokenPromisesLockerRoomRevoltPanel'],
      category: Package2TaskCategory.service,
      description: 'Konsekwencje złamanych obietnic lidera i bunt w szatni',
    ),
    Package2TaskSpec(
      taskNumber: 230,
      filePath: 'lib/services/career/regional_scouting_networks_service.dart',
      primarySymbols: ['RegionalScoutingNetworksService', 'RegionalScoutingNetworksPanel'],
      category: Package2TaskCategory.service,
      description: 'System 8 regionalnych siatek skautingowych ze specjalizacją',
    ),
    Package2TaskSpec(
      taskNumber: 231,
      filePath: 'lib/services/career/youth_race_calendar_u23_simulator.dart',
      primarySymbols: ['YouthRaceCalendarU23Simulator', 'YouthRaceCalendarU23Panel'],
      category: Package2TaskCategory.service,
      description: 'Symulator wyścigów młodzieżowych U23 i skautingu W/kg',
    ),
    Package2TaskSpec(
      taskNumber: 232,
      filePath: 'lib/services/career/dynamic_inflation_and_market_boom_service.dart',
      primarySymbols: ['DynamicInflationAndMarketBoomService', 'DynamicInflationMarketBoomPanel'],
      category: Package2TaskCategory.service,
      description: 'Wieloletni model ekonomiczny świata kolarstwa 2026–2040',
    ),
    Package2TaskSpec(
      taskNumber: 233,
      filePath: 'lib/services/career/rider_mentorship_and_tutoring_service.dart',
      primarySymbols: ['RiderMentorshipAndTutoringService', 'RiderMentorshipAndTutoringPanel'],
      category: Package2TaskCategory.service,
      description: 'System mentoringu weteranów dla 19-letnich neoprofesjonalistów',
    ),
    Package2TaskSpec(
      taskNumber: 234,
      filePath: 'lib/services/career/overtraining_and_burnout_diagnostics.dart',
      primarySymbols: ['OvertrainingAndBurnoutDiagnostics', 'OvertrainingAndBurnoutDiagnosticsPanel'],
      category: Package2TaskCategory.service,
      description: 'Diagnostyka przetrenowania parasympatycznego i wypalenia',
    ),
    Package2TaskSpec(
      taskNumber: 235,
      filePath: 'lib/services/career/altitude_camp_acclimatization_curve.dart',
      primarySymbols: ['AltitudeCampAcclimatizationCurve'],
      category: Package2TaskCategory.service,
      description: 'Fizjologiczny model obozów wysokogórskich (Sierra Nevada/Teide/Livigno)',
    ),
    Package2TaskSpec(
      taskNumber: 236,
      filePath: 'lib/engine/rendering3d/render_object_pool_manager.dart',
      primarySymbols: ['RenderObjectPoolManager', 'RenderObjectPoolInspectorPanel'],
      category: Package2TaskCategory.engine3d,
      description: 'Menedżer puli obiektów 3D Zero-GC 120 FPS (Float64List)',
    ),
    Package2TaskSpec(
      taskNumber: 237,
      filePath: 'lib/engine/rendering3d/frustum_and_distance_culler.dart',
      primarySymbols: ['FrustumAndDistanceCuller', 'FrustumCullingInspectorPanel'],
      category: Package2TaskCategory.engine3d,
      description: 'System odrzucania obiektów poza polem widzenia kamery (>450 m)',
    ),
    Package2TaskSpec(
      taskNumber: 238,
      filePath: 'lib/engine/rendering3d/spatial_hash_grid_1d_2d.dart',
      primarySymbols: ['SpatialHashGrid1d2d'],
      category: Package2TaskCategory.engine3d,
      description: 'Siatka przestrzenna O(N) z koszykami co 5 m dla 176 kolarzy',
    ),
    Package2TaskSpec(
      taskNumber: 239,
      filePath: 'lib/engine/simulation/deterministic_rng_seed_manager.dart',
      primarySymbols: ['DeterministicRngSeedManager'],
      category: Package2TaskCategory.simulation,
      description: 'Deterministyczny menedżer RNG oparty na stageSeed',
    ),
    Package2TaskSpec(
      taskNumber: 240,
      filePath: 'lib/ui/widgets/animated_screen_transition_router.dart',
      primarySymbols: ['AnimatedScreenTransitionRouter'],
      category: Package2TaskCategory.uiWidget,
      description: 'Zestaw płynnych przejść GoRouter i SharedAxisTransition',
    ),
    Package2TaskSpec(
      taskNumber: 241,
      filePath: 'lib/ui/widgets/interactive_career_timeline_history_widget.dart',
      primarySymbols: ['InteractiveCareerTimelineHistoryWidget'],
      category: Package2TaskCategory.uiWidget,
      description: 'Interaktywna oś czasu kariery menedżera rok po roku',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 242,
      filePath: 'lib/ui/widgets/team_kit_evolution_gallery_widget.dart',
      primarySymbols: ['TeamKitEvolutionGalleryWidget'],
      category: Package2TaskCategory.uiWidget,
      description: 'Galeria ewolucji historycznych koszulek i rowerów drużyny',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 243,
      filePath: 'lib/ui/widgets/rival_managers_head_to_head_widget.dart',
      primarySymbols: ['RivalManagersHeadToHeadWidget'],
      category: Package2TaskCategory.uiWidget,
      description: 'Ekran rywalizacji H2H z dyrektorami sportowymi WorldTour',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 244,
      filePath: 'lib/ui/widgets/monument_cobble_sectors_inspector_modal.dart',
      primarySymbols: ['MonumentCobbleSectorsInspectorModal'],
      category: Package2TaskCategory.uiWidget,
      description: 'Inspektor sektorów brukowanych i szutrowych monumentów',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 245,
      filePath: 'lib/ui/widgets/grand_tour_jersey_point_rules_modal.dart',
      primarySymbols: ['GrandTourJerseyPointRulesModal'],
      category: Package2TaskCategory.uiWidget,
      description: 'Modal zasad punktacji, bonifikat i kalkulatora OTL',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 246,
      filePath: 'lib/ui/widgets/live_team_car_gap_indicator_hud.dart',
      primarySymbols: ['LiveTeamCarGapIndicatorHud'],
      category: Package2TaskCategory.uiWidget,
      description: 'Wskaźnik odległości wozu technicznego i blokady Barrage Active',
    ),
    Package2TaskSpec(
      taskNumber: 247,
      filePath: 'lib/engine/events/commissaire_jury_penalties_engine.dart',
      primarySymbols: ['CommissaireJuryPenaltiesEngine', 'CommissaireJuryCommuniquesPanel'],
      category: Package2TaskCategory.pelotonAi,
      description: 'System sędziowski UCI (Sticky Bottle, Irregular Sprint, grzywny CHF)',
    ),
    Package2TaskSpec(
      taskNumber: 248,
      filePath: 'lib/ui/widgets/jury_communique_report_modal.dart',
      primarySymbols: ['JuryCommuniqueReportModal'],
      category: Package2TaskCategory.uiWidget,
      description: 'Oficjalny komunikat Kolegium Sędziów UCI po etapie',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 249,
      filePath: 'lib/engine/peloton/combativity_award_jury_evaluator.dart',
      primarySymbols: ['CombativityAwardJuryEvaluator', 'CombativityAwardJuryPanel'],
      category: Package2TaskCategory.pelotonAi,
      description: 'Algorytm wyboru Najaktywniejszego Kolarza Etapu (czerwony numer)',
    ),
    Package2TaskSpec(
      taskNumber: 250,
      filePath: 'lib/ui/widgets/stage_favorites_bookmakers_odds_card.dart',
      primarySymbols: ['StageFavoritesBookmakersOddsCard'],
      category: Package2TaskCategory.uiWidget,
      description: 'Karta faworytów i kursów przedetapowych (1–5 gwiazdek)',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 251,
      filePath: 'lib/ui/widgets/post_race_watts_per_kg_leaderboard_card.dart',
      primarySymbols: ['PostRaceWattsPerKgLeaderboardCard'],
      category: Package2TaskCategory.uiWidget,
      description: 'Tabela rekordów mocy dnia po etapie (5s/1m/5m/20m)',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 252,
      filePath: 'lib/services/career/season_awards_velo_dor_ceremony.dart',
      primarySymbols: ['SeasonAwardsVeloDorCeremony', 'VeloDorCeremonyGalaWidget'],
      category: Package2TaskCategory.service,
      description: 'Doroczny plebiscyt Vélo d\'Or na koniec października',
    ),
    Package2TaskSpec(
      taskNumber: 253,
      filePath: 'lib/ui/screens/velo_dor_gala_ceremony_screen.dart',
      primarySymbols: ['VeloDorGalaCeremonyScreen'],
      category: Package2TaskCategory.uiScreen,
      description: 'Uroczysty ekran gali kończącej sezon Vélo d\'Or',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 254,
      filePath: 'lib/services/database/database_backup_and_integrity_repair.dart',
      primarySymbols: [
        'DatabaseBackupAndIntegrityRepair',
        'DatabaseBackupAndIntegrityRepairPanel',
      ],
      category: Package2TaskCategory.service,
      description: 'Automatyczny system naprawy, migracji schematu i kopii .bak',
    ),
    Package2TaskSpec(
      taskNumber: 255,
      filePath: 'lib/ui/widgets/fps_and_simulation_telemetry_overlay.dart',
      primarySymbols: ['FpsAndSimulationTelemetryOverlay'],
      category: Package2TaskCategory.uiWidget,
      description: 'Nakładka wydajności FPS, Isolate ms, wielokątów 3D i RAM',
    ),
    Package2TaskSpec(
      taskNumber: 256,
      filePath: 'test/alpine_climb_and_itt_realism_test.dart',
      primarySymbols: ['main'],
      category: Package2TaskCategory.testSuite,
      description: 'Test regresji balansu Alpe d\'Huez i 40 km ITT',
    ),
    Package2TaskSpec(
      taskNumber: 257,
      filePath: 'test/sprint_train_and_leadout_test.dart',
      primarySymbols: ['main'],
      category: Package2TaskCategory.testSuite,
      description: 'Test regresji pociągów sprinterskich na ostatnich 3 km',
    ),
    Package2TaskSpec(
      taskNumber: 258,
      filePath: 'test/grand_tour_21_stages_endurance_test.dart',
      primarySymbols: ['main'],
      category: Package2TaskCategory.testSuite,
      description: 'Test wytrzymałościowy 21 kolejnych etapów Wielkiego Touru',
    ),
    Package2TaskSpec(
      taskNumber: 259,
      filePath: 'test/transfer_market_and_clauses_test.dart',
      primarySymbols: ['main'],
      category: Package2TaskCategory.testSuite,
      description: 'Test regresji rynku transferowego AI i klauzul kontraktowych',
    ),
    Package2TaskSpec(
      taskNumber: 260,
      filePath: 'test/rendering_3d_culling_and_boids_test.dart',
      primarySymbols: ['main'],
      category: Package2TaskCategory.testSuite,
      description: 'Test wydajnościowy 1000 kroków Boids + Scene3D (<2.0 ms/klatkę)',
    ),
    Package2TaskSpec(
      taskNumber: 261,
      filePath: 'lib/core/diagnostics/code_map_auto_synchronizer.dart',
      primarySymbols: ['CodeMapAutoSynchronizer', 'CodeMapAutoSynchronizerPanel'],
      category: Package2TaskCategory.diagnostics,
      description: 'Automatyczny synchronizator architektury CODE_MAP.md i importów',
      requiresResponsiveLayout: true,
    ),
    Package2TaskSpec(
      taskNumber: 262,
      filePath: 'lib/core/diagnostics/sniper_package_2_audit_runner.dart',
      primarySymbols: ['SniperPackage2AuditRunner', 'SniperPackage2AuditPanel'],
      category: Package2TaskCategory.diagnostics,
      description: 'Skrypt audytowy integracji Paczki #2 (#213–#262) i flutter analyze',
      requiresResponsiveLayout: true,
    ),
  ];

  /// Rozwiązuje katalog główny projektu zawierający `pubspec.yaml` i `docs/CODE_MAP.md`.
  static String resolveProjectRoot([String? explicitRoot]) {
    if (explicitRoot != null && explicitRoot.trim().isNotEmpty) {
      return Directory(explicitRoot).absolute.path;
    }
    var current = Directory.current.absolute;
    for (var i = 0; i < 8; i++) {
      final pubspec = File('${current.path}${Platform.pathSeparator}pubspec.yaml');
      final codeMap = File(
        '${current.path}${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md',
      );
      if (pubspec.existsSync() && codeMap.existsSync()) {
        return current.path;
      }
      final parent = current.parent;
      if (parent.path == current.path) break;
      current = parent;
    }
    return Directory.current.absolute.path;
  }

  /// Uruchamia pełny audyt integracji Paczki #2 (#213–#262).
  Future<Package2AuditReport> runFullAudit({
    String? projectRoot,
    bool runFlutterAnalyze = true,
    Future<Package2FlutterAnalyzeResult> Function(String root)?
        customAnalyzeRunner,
  }) async {
    final stopwatch = Stopwatch()..start();
    final root = resolveProjectRoot(projectRoot);
    final codeMapFile = File(
      '$root${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md',
    );
    final codeMapContent =
        codeMapFile.existsSync() ? codeMapFile.readAsStringSync() : null;

    final corpus = _loadDartCorpus(root);

    final taskResults = <Package2TaskAuditResult>[
      for (final spec in package2Manifest)
        auditSingleTask(
          spec,
          projectRoot: root,
          codeMapContent: codeMapContent,
          corpus: corpus,
        ),
    ];

    final codeMapResult = auditCodeMap(
      projectRoot: root,
      codeMapContent: codeMapContent,
    );

    final integrationResult = auditGameIntegration(
      projectRoot: root,
      taskResults: taskResults,
      corpus: corpus,
    );

    final analyzeResult = runFlutterAnalyze
        ? await (customAnalyzeRunner != null
            ? customAnalyzeRunner(root)
            : runFlutterAnalyzeProcess(root))
        : Package2FlutterAnalyzeResult.skipped();

    stopwatch.stop();
    return Package2AuditReport(
      generatedAt: DateTime.now(),
      projectRoot: root,
      taskResults: taskResults,
      codeMapResult: codeMapResult,
      integrationResult: integrationResult,
      analyzeResult: analyzeResult,
      duration: stopwatch.elapsed,
    );
  }

  /// Audytuje pojedynczy plik z manifestu Paczki #2.
  Package2TaskAuditResult auditSingleTask(
    Package2TaskSpec spec, {
    required String projectRoot,
    String? codeMapContent,
    Package2DartCorpusIndex? corpus,
  }) {
    final normalizedRelative =
        spec.filePath.replaceAll('/', Platform.pathSeparator);
    final file = File('$projectRoot${Platform.pathSeparator}$normalizedRelative');
    final issues = <String>[];

    if (!file.existsSync()) {
      issues.add('Brak pliku na dysku: ${spec.filePath}');
      return Package2TaskAuditResult(
        spec: spec,
        fileExists: false,
        fileSizeBytes: 0,
        lineCount: 0,
        presentSymbols: const [],
        missingSymbols: spec.primarySymbols,
        todoMarkersCount: 0,
        unimplementedThrowsCount: 0,
        inCodeMap: codeMapContent != null && codeMapContent.contains(spec.filePath),
        missingSymbolsInCodeMap: spec.primarySymbols,
        hasResponsiveLayout: false,
        usesAppColors: false,
        brokenRelativeImports: const [],
        libReferencesCount: 0,
        testReferencesCount: 0,
        issues: issues,
      );
    }

    final content = file.readAsStringSync();
    final bytes = file.lengthSync();
    final lines = const LineSplitter().convert(content);

    final presentSymbols = <String>[];
    final missingSymbols = <String>[];

    for (final symbol in spec.primarySymbols) {
      if (_containsSymbolDeclaration(content, symbol)) {
        presentSymbols.add(symbol);
      } else {
        missingSymbols.add(symbol);
        issues.add('Brak deklaracji symbolu `$symbol`');
      }
    }

    final todoRegex = RegExp(
      r'^\s*//\s*(TODO|FIXME)\b',
      caseSensitive: false,
      multiLine: true,
    );
    final unimplementedRegex = RegExp(r'\bthrow\s+UnimplementedError\s*\(');
    final todoCount = todoRegex.allMatches(content).length;
    final unimplementedCount = unimplementedRegex.allMatches(content).length;

    if (todoCount > 0) {
      issues.add('Wykryto niedokończone znaczniki TODO/FIXME ($todoCount)');
    }
    if (unimplementedCount > 0) {
      issues.add('Wykryto UnimplementedError ($unimplementedCount)');
    }

    final inCodeMap =
        codeMapContent != null && codeMapContent.contains(spec.filePath);
    if (!inCodeMap) {
      issues.add('Brak wpisu w docs/CODE_MAP.md');
    }

    final missingCodeMapSymbols = <String>[];
    if (codeMapContent != null &&
        spec.category != Package2TaskCategory.testSuite) {
      for (final symbol in spec.primarySymbols) {
        if (!codeMapContent.contains(symbol)) {
          missingCodeMapSymbols.add(symbol);
        }
      }
    }

    final hasResponsiveLayout =
        content.contains('LayoutBuilder') || content.contains('MediaQuery');
    final usesAppColors =
        content.contains('AppColors') || content.contains('AppTheme');

    if (spec.requiresResponsiveLayout && !hasResponsiveLayout) {
      issues.add('Brak responsywnego LayoutBuilder/MediaQuery');
    }

    final brokenImports = _findBrokenRelativeImports(
      content: content,
      fileDir: file.parent,
      projectRoot: projectRoot,
    );
    if (brokenImports.isNotEmpty) {
      issues.add('Uszkodzone importy względne: ${brokenImports.join(', ')}');
    }

    final effectiveCorpus = corpus ?? _loadDartCorpus(projectRoot);
    final refCounts = _countCrossReferences(
      spec: spec,
      corpus: effectiveCorpus,
    );

    return Package2TaskAuditResult(
      spec: spec,
      fileExists: true,
      fileSizeBytes: bytes,
      lineCount: lines.length,
      presentSymbols: presentSymbols,
      missingSymbols: missingSymbols,
      todoMarkersCount: todoCount,
      unimplementedThrowsCount: unimplementedCount,
      inCodeMap: inCodeMap,
      missingSymbolsInCodeMap: missingCodeMapSymbols,
      hasResponsiveLayout: hasResponsiveLayout,
      usesAppColors: usesAppColors,
      brokenRelativeImports: brokenImports,
      libReferencesCount: refCounts.libCount,
      testReferencesCount: refCounts.testCount,
      issues: issues,
    );
  }

  /// Weryfikuje kompletność wpisów dla Paczki #2 w `docs/CODE_MAP.md`.
  Package2CodeMapAuditResult auditCodeMap({
    required String projectRoot,
    String? codeMapContent,
    List<Package2TaskSpec>? manifest,
  }) {
    final effectiveManifest = manifest ?? package2Manifest;
    final codeMapFile = File(
      '$projectRoot${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md',
    );
    final exists = codeMapContent != null || codeMapFile.existsSync();
    if (!exists) {
      return Package2CodeMapAuditResult(
        codeMapExists: false,
        totalLines: 0,
        package2CoveredCount: 0,
        missingFilePaths: effectiveManifest.map((e) => e.filePath).toList(),
        missingSymbolsByFile: const {},
      );
    }

    final content = codeMapContent ?? codeMapFile.readAsStringSync();
    final totalLines = const LineSplitter().convert(content).length;
    final missingFilePaths = <String>[];
    final missingSymbolsByFile = <String, List<String>>{};
    var covered = 0;

    for (final spec in effectiveManifest) {
      if (content.contains(spec.filePath)) {
        covered++;
      } else {
        missingFilePaths.add(spec.filePath);
      }
      if (spec.category != Package2TaskCategory.testSuite) {
        final missingSym = spec.primarySymbols
            .where((sym) => !content.contains(sym))
            .toList();
        if (missingSym.isNotEmpty) {
          missingSymbolsByFile[spec.filePath] = missingSym;
        }
      }
    }

    return Package2CodeMapAuditResult(
      codeMapExists: true,
      totalLines: totalLines,
      package2CoveredCount: covered,
      missingFilePaths: missingFilePaths,
      missingSymbolsByFile: missingSymbolsByFile,
    );
  }

  /// Weryfikuje integrację modułów Paczki #2 z resztą gry.
  Package2IntegrationCheckResult auditGameIntegration({
    required String projectRoot,
    required List<Package2TaskAuditResult> taskResults,
    Package2DartCorpusIndex? corpus,
  }) {
    final effectiveCorpus = corpus ?? _loadDartCorpus(projectRoot);
    final verifiedBridges = <String>[];
    final missingBridges = <String>[];

    for (final bridge in coreIntegrationBridges) {
      final normalized = bridge.replaceAll('/', Platform.pathSeparator);
      final bridgeFile = File('$projectRoot${Platform.pathSeparator}$normalized');
      if (bridgeFile.existsSync() && bridgeFile.lengthSync() > 0) {
        verifiedBridges.add(bridge);
      } else {
        missingBridges.add(bridge);
      }
    }

    final brokenByFile = <String, List<String>>{};
    var integrableCount = 0;
    var integratedCount = 0;

    for (final result in taskResults) {
      if (result.brokenRelativeImports.isNotEmpty) {
        brokenByFile[result.spec.filePath] = result.brokenRelativeImports;
      }
      if (result.spec.category != Package2TaskCategory.testSuite &&
          result.spec.taskNumber != 262) {
        integrableCount++;
        if (result.totalReferencesCount > 0) {
          integratedCount++;
        }
      }
    }

    return Package2IntegrationCheckResult(
      totalScannedLibFiles: effectiveCorpus.libFiles.length,
      totalScannedTestFiles: effectiveCorpus.testFiles.length,
      verifiedCoreBridges: verifiedBridges,
      missingCoreBridges: missingBridges,
      brokenRelativeImportsByFile: brokenByFile,
      integratedTasksCount: integratedCount,
      totalIntegrableTasksCount: integrableCount,
    );
  }

  /// Uruchamia `flutter analyze` w katalogu projektu i parsuje wyniki.
  Future<Package2FlutterAnalyzeResult> runFlutterAnalyzeProcess(
    String projectRoot, {
    List<String>? targetPaths,
  }) async {
    final stopwatch = Stopwatch()..start();
    final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final args = <String>[
      'analyze',
      '--no-pub',
      ...?targetPaths,
    ];

    try {
      final result = await Process.run(
        executable,
        args,
        workingDirectory: projectRoot,
        runInShell: Platform.isWindows,
      );
      stopwatch.stop();
      final stdoutText = result.stdout?.toString() ?? '';
      final stderrText = result.stderr?.toString() ?? '';
      final combined = '$stdoutText\n$stderrText'.trim();
      final issues = parseFlutterAnalyzeOutput(combined);

      final errors =
          issues.where((i) => i.severity == Package2AuditSeverity.error).length;
      final warnings = issues
          .where((i) => i.severity == Package2AuditSeverity.warning)
          .length;
      final infos =
          issues.where((i) => i.severity == Package2AuditSeverity.info).length;

      return Package2FlutterAnalyzeResult(
        executed: true,
        exitCode: result.exitCode,
        errorCount: errors,
        warningCount: warnings,
        infoCount: infos,
        issues: issues,
        rawOutput: combined,
        duration: stopwatch.elapsed,
      );
    } on ProcessException catch (e) {
      stopwatch.stop();
      return Package2FlutterAnalyzeResult(
        executed: true,
        exitCode: -1,
        errorCount: 1,
        warningCount: 0,
        infoCount: 0,
        issues: [
          Package2AnalyzeIssue(
            severity: Package2AuditSeverity.error,
            message: 'Nie udało się uruchomić flutter analyze: ${e.message}',
            filePath: '',
            line: 0,
            column: 0,
            ruleName: 'process_error',
          ),
        ],
        rawOutput: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Parsuje standardowe linie wyjścia `flutter analyze`.
  static List<Package2AnalyzeIssue> parseFlutterAnalyzeOutput(String output) {
    final issues = <Package2AnalyzeIssue>[];
    final lines = const LineSplitter().convert(output);
    final pattern = RegExp(
      r'^\s*(error|warning|info)\s*[•-]\s*(.+?)\s*[•-]\s*(.+?):(\d+):(\d+)\s*[•-]\s*([a-z0-9_]+)\s*$',
      caseSensitive: false,
    );

    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match == null) continue;
      final severityStr = match.group(1)!.toLowerCase();
      final severity = switch (severityStr) {
        'error' => Package2AuditSeverity.error,
        'warning' => Package2AuditSeverity.warning,
        _ => Package2AuditSeverity.info,
      };
      issues.add(
        Package2AnalyzeIssue(
          severity: severity,
          message: match.group(2)!.trim(),
          filePath: match.group(3)!.trim(),
          line: int.tryParse(match.group(4)!) ?? 0,
          column: int.tryParse(match.group(5)!) ?? 0,
          ruleName: match.group(6)!.trim(),
        ),
      );
    }
    return issues;
  }

  static bool _containsSymbolDeclaration(String content, String symbol) {
    if (symbol == 'main') {
      return RegExp(r'\b(?:Future<void>|void)\s+main\s*\(').hasMatch(content);
    }
    final escaped = RegExp.escape(symbol);
    final pattern = RegExp(
      r'\b(?:abstract\s+(?:interface\s+|base\s+|final\s+)?class|class|enum|mixin|extension|typedef)\s+' +
          escaped +
          r'\b',
    );
    return pattern.hasMatch(content);
  }

  static List<String> _findBrokenRelativeImports({
    required String content,
    required Directory fileDir,
    required String projectRoot,
  }) {
    final broken = <String>[];
    final importPattern = RegExp(
      r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    for (final match in importPattern.allMatches(content)) {
      final uri = match.group(1)!;
      if (uri.startsWith('dart:')) continue;
      if (uri.startsWith('package:')) {
        const prefix = 'package:pro_peloton_manager/';
        if (uri.startsWith(prefix)) {
          final rel = uri.substring(prefix.length).replaceAll('/', Platform.pathSeparator);
          final target = File('$projectRoot${Platform.pathSeparator}lib${Platform.pathSeparator}$rel');
          if (!target.existsSync()) {
            broken.add(uri);
          }
        }
        continue;
      }
      final resolved = File('${fileDir.path}${Platform.pathSeparator}${uri.replaceAll('/', Platform.pathSeparator)}');
      if (!resolved.existsSync()) {
        broken.add(uri);
      }
    }
    return broken;
  }

  static Package2DartCorpusIndex _loadDartCorpus(String projectRoot) {
    final libFiles = <String, String>{};
    final testFiles = <String, String>{};

    void scanDir(String subDir, Map<String, String> target) {
      final dir = Directory('$projectRoot${Platform.pathSeparator}$subDir');
      if (!dir.existsSync()) return;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relative = entity.path
            .substring(projectRoot.length + 1)
            .replaceAll(Platform.pathSeparator, '/');
        try {
          target[relative] = entity.readAsStringSync();
        } on FileSystemException {
          // Pomijamy nieczytelne pliki tymczasowe.
        }
      }
    }

    scanDir('lib', libFiles);
    scanDir('test', testFiles);
    return Package2DartCorpusIndex(libFiles: libFiles, testFiles: testFiles);
  }

  static ({int libCount, int testCount}) _countCrossReferences({
    required Package2TaskSpec spec,
    required Package2DartCorpusIndex corpus,
  }) {
    final fileName = spec.filePath.split('/').last;
    var libCount = 0;
    var testCount = 0;

    bool referencesSpec(String path, String content) {
      if (path == spec.filePath) return false;
      if (content.contains(fileName)) return true;
      for (final sym in spec.primarySymbols) {
        if (sym != 'main' && content.contains(sym)) return true;
      }
      return false;
    }

    for (final entry in corpus.libFiles.entries) {
      if (referencesSpec(entry.key, entry.value)) {
        libCount++;
      }
    }
    for (final entry in corpus.testFiles.entries) {
      if (referencesSpec(entry.key, entry.value)) {
        testCount++;
      }
    }

    return (libCount: libCount, testCount: testCount);
  }
}

class Package2DartCorpusIndex {
  final Map<String, String> libFiles;
  final Map<String, String> testFiles;

  const Package2DartCorpusIndex({
    required this.libFiles,
    required this.testFiles,
  });
}

/// Stan kontrolera audytu Paczki #2 w Riverpod.
@immutable
class SniperPackage2AuditState {
  final bool isRunning;
  final Package2AuditReport? report;
  final String? errorMessage;
  final Package2TaskCategory? selectedCategory;
  final bool onlyFailures;
  final String searchQuery;

  const SniperPackage2AuditState({
    this.isRunning = false,
    this.report,
    this.errorMessage,
    this.selectedCategory,
    this.onlyFailures = false,
    this.searchQuery = '',
  });

  SniperPackage2AuditState copyWith({
    bool? isRunning,
    Package2AuditReport? report,
    String? errorMessage,
    bool clearError = false,
    Package2TaskCategory? selectedCategory,
    bool clearCategory = false,
    bool? onlyFailures,
    String? searchQuery,
  }) {
    return SniperPackage2AuditState(
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      onlyFailures: onlyFailures ?? this.onlyFailures,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<Package2TaskAuditResult> get filteredResults {
    final results = report?.taskResults ?? const <Package2TaskAuditResult>[];
    final q = searchQuery.trim().toLowerCase();
    return results.where((item) {
      if (selectedCategory != null && item.spec.category != selectedCategory) {
        return false;
      }
      if (onlyFailures && item.passed) {
        return false;
      }
      if (q.isNotEmpty) {
        final matchNumber = '#${item.spec.taskNumber}'.contains(q);
        final matchPath = item.spec.filePath.toLowerCase().contains(q);
        final matchSymbol = item.spec.primarySymbols.any(
          (s) => s.toLowerCase().contains(q),
        );
        if (!matchNumber && !matchPath && !matchSymbol) {
          return false;
        }
      }
      return true;
    }).toList();
  }
}

/// Notifier zarządzający wykonywaniem i filtrowaniem audytu Paczki #2.
class SniperPackage2AuditNotifier
    extends StateNotifier<SniperPackage2AuditState> {
  final SniperPackage2AuditRunner _runner;
  final String? _projectRoot;

  SniperPackage2AuditNotifier({
    SniperPackage2AuditRunner runner = const SniperPackage2AuditRunner(),
    String? projectRoot,
  })  : _runner = runner,
        _projectRoot = projectRoot,
        super(const SniperPackage2AuditState());

  Future<void> runAudit({bool includeFlutterAnalyze = true}) async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, clearError: true);
    try {
      final report = await _runner.runFullAudit(
        projectRoot: _projectRoot,
        runFlutterAnalyze: includeFlutterAnalyze,
      );
      if (!mounted) return;
      state = state.copyWith(isRunning: false, report: report);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Błąd audytu Paczki #2: $e',
      );
    }
  }

  void setCategoryFilter(Package2TaskCategory? category) {
    if (category == state.selectedCategory) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setOnlyFailures(bool value) {
    state = state.copyWith(onlyFailures: value);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Globalny provider audytu Paczki #2 (#213–#262).
final sniperPackage2AuditProvider = StateNotifierProvider.autoDispose<
    SniperPackage2AuditNotifier, SniperPackage2AuditState>(
  (ref) => SniperPackage2AuditNotifier(),
);

/// Responsywny panel UI prezentujący wyniki audytu integracji Paczki #2 (#213–#262).
class SniperPackage2AuditPanel extends ConsumerStatefulWidget {
  final String? projectRoot;
  final bool autoRunOnInit;
  final bool includeFlutterAnalyzeByDefault;

  const SniperPackage2AuditPanel({
    super.key,
    this.projectRoot,
    this.autoRunOnInit = false,
    this.includeFlutterAnalyzeByDefault = false,
  });

  @override
  ConsumerState<SniperPackage2AuditPanel> createState() =>
      _SniperPackage2AuditPanelState();
}

class _SniperPackage2AuditPanelState
    extends ConsumerState<SniperPackage2AuditPanel> {
  late bool _includeFlutterAnalyze;
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _expandedTasks = <int>{};

  @override
  void initState() {
    super.initState();
    _includeFlutterAnalyze = widget.includeFlutterAnalyzeByDefault;
    if (widget.autoRunOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(sniperPackage2AuditProvider.notifier)
            .runAudit(includeFlutterAnalyze: _includeFlutterAnalyze);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sniperPackage2AuditProvider);
    final notifier = ref.read(sniperPackage2AuditProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;
          final isMedium =
              constraints.maxWidth >= 680 && constraints.maxWidth < 1150;

          return Padding(
            padding: EdgeInsets.all(isCompact ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(state, notifier, isCompact),
                const SizedBox(height: 16),
                if (state.errorMessage != null) ...[
                  _buildErrorBanner(state.errorMessage!),
                  const SizedBox(height: 16),
                ],
                _buildKpiGrid(state.report, isCompact, isMedium),
                const SizedBox(height: 16),
                _buildFilterBar(state, notifier, isCompact),
                const SizedBox(height: 12),
                _buildResultsList(state, isCompact),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    SniperPackage2AuditState state,
    SniperPackage2AuditNotifier notifier,
    bool isCompact,
  ) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.4),
                ),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Audyt Integracji Paczki #2 (#213–#262)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Weryfikacja integracji z resztą gry, mostów silnika, docs/CODE_MAP.md oraz flutter analyze.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final controlsSection = Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Package2AuditToggle(
          label: 'flutter analyze',
          value: _includeFlutterAnalyze,
          enabled: !state.isRunning,
          onChanged: (v) => setState(() => _includeFlutterAnalyze = v),
        ),
        _Package2AuditButton(
          label: state.isRunning ? 'Skanowanie...' : 'Uruchom Audyt',
          icon: state.isRunning
              ? Icons.hourglass_top_rounded
              : Icons.play_arrow_rounded,
          enabled: !state.isRunning,
          onPressed: () =>
              notifier.runAudit(includeFlutterAnalyze: _includeFlutterAnalyze),
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleSection,
          const SizedBox(height: 12),
          controlsSection,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 16),
        controlsSection,
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.crimsonAlert.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.crimsonAlert),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    Package2AuditReport? report,
    bool isCompact,
    bool isMedium,
  ) {
    final cards = [
      _Package2KpiCard(
        title: 'Zadania #213–#262',
        value: report == null
            ? '50 / 50'
            : '${report.passedTasks} / ${report.totalTasks}',
        subtitle: report == null
            ? 'Gotowe do audytu'
            : (report.failedTasks == 0
                ? '100% spójności'
                : '${report.failedTasks} wymaga uwagi'),
        accent: report == null
            ? AppColors.accentBlue
            : (report.failedTasks == 0
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert),
        icon: Icons.layers_rounded,
      ),
      _Package2KpiCard(
        title: 'Integracja z grą',
        value: report == null
            ? '—'
            : '${report.integrationResult.verifiedCoreBridges.length} / ${SniperPackage2AuditRunner.coreIntegrationBridges.length}',
        subtitle: report == null
            ? 'Mosty i referencje'
            : '${report.integrationResult.integratedTasksCount}/${report.integrationResult.totalIntegrableTasksCount} powiązanych',
        accent: report == null
            ? AppColors.textSecondary
            : (report.integrationResult.passed
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert),
        icon: Icons.hub_rounded,
      ),
      _Package2KpiCard(
        title: 'docs/CODE_MAP.md',
        value: report == null
            ? '—'
            : '${report.codeMapResult.package2CoveredCount} / 50',
        subtitle: report == null
            ? 'Weryfikacja wpisów'
            : (report.codeMapResult.passed
                ? 'Kompletna mapa kodu'
                : 'Brak ${report.codeMapResult.missingFilePaths.length} ścieżek'),
        accent: report == null
            ? AppColors.textSecondary
            : (report.codeMapResult.passed
                ? AppColors.statusSuccess
                : AppColors.amberWarning),
        icon: Icons.map_rounded,
      ),
      _Package2KpiCard(
        title: 'flutter analyze',
        value: report == null
            ? '—'
            : (report.analyzeResult.executed
                ? '${report.analyzeResult.errorCount}E / ${report.analyzeResult.warningCount}W'
                : 'Pominięto'),
        subtitle: report == null
            ? 'Analiza statyczna'
            : (report.analyzeResult.passed
                ? 'Zero ostrzeżeń'
                : 'Wykryto problemy lintera'),
        accent: report == null
            ? AppColors.goldAccent
            : (report.analyzeResult.passed
                ? AppColors.goldAccent
                : AppColors.crimsonAlert),
        icon: Icons.code_rounded,
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (isMedium) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: cards[2]),
              const SizedBox(width: 12),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: 12),
        ],
      ],
    );
  }

  Widget _buildFilterBar(
    SniperPackage2AuditState state,
    SniperPackage2AuditNotifier notifier,
    bool isCompact,
  ) {
    final searchField = TextField(
      controller: _searchController,
      onChanged: notifier.setSearchQuery,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Szukaj po numerze (#213), pliku lub symbolu...',
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 18,
        ),
        filled: true,
        fillColor: AppColors.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.goldAccent),
        ),
      ),
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Package2FilterChip(
          label: 'Tylko błędy',
          selected: state.onlyFailures,
          onTap: () => notifier.setOnlyFailures(!state.onlyFailures),
        ),
        for (final category in Package2TaskCategory.values)
          _Package2FilterChip(
            label: category.label,
            icon: category.icon,
            selected: state.selectedCategory == category,
            onTap: () => notifier.setCategoryFilter(category),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isCompact) ...[
          searchField,
          const SizedBox(height: 10),
          chips,
        ] else ...[
          Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              _Package2FilterChip(
                label: 'Tylko błędy',
                selected: state.onlyFailures,
                onTap: () => notifier.setOnlyFailures(!state.onlyFailures),
              ),
            ],
          ),
          const SizedBox(height: 10),
          chips,
        ],
      ],
    );
  }

  Widget _buildResultsList(SniperPackage2AuditState state, bool isCompact) {
    if (state.report == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.radar_rounded,
              color: AppColors.goldAccent,
              size: 36,
            ),
            SizedBox(height: 10),
            Text(
              'Kliknij „Uruchom Audyt”, aby zweryfikować integrację wszystkich 50 zadań Paczki #2 (#213–#262).',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    final items = state.filteredResults;
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Text(
          'Brak zadań spełniających wybrane kryteria filtrowania.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _Package2TaskAuditRow(
            result: items[i],
            isCompact: isCompact,
            expanded: _expandedTasks.contains(items[i].spec.taskNumber),
            onToggleExpand: () {
              setState(() {
                final num = items[i].spec.taskNumber;
                if (_expandedTasks.contains(num)) {
                  _expandedTasks.remove(num);
                } else {
                  _expandedTasks.add(num);
                }
              });
            },
          ),
          if (i < items.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _Package2KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _Package2KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Package2TaskAuditRow extends StatefulWidget {
  final Package2TaskAuditResult result;
  final bool isCompact;
  final bool expanded;
  final VoidCallback onToggleExpand;

  const _Package2TaskAuditRow({
    required this.result,
    required this.isCompact,
    required this.expanded,
    required this.onToggleExpand,
  });

  @override
  State<_Package2TaskAuditRow> createState() => _Package2TaskAuditRowState();
}

class _Package2TaskAuditRowState extends State<_Package2TaskAuditRow> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final severity = widget.result.severity;
    final bgColor = _pressed
        ? AppColors.surfaceLight
        : (_hovered ? AppColors.surfaceLight.withValues(alpha: 0.75) : AppColors.surface);
    final borderColor = _focused
        ? AppColors.goldAccent
        : (_hovered ? severity.color.withValues(alpha: 0.65) : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onToggleExpand,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severity.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${widget.result.spec.taskNumber}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: severity.color,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.result.spec.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.result.spec.filePath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isCompact) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Ref: ${widget.result.totalReferencesCount}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    widget.expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (widget.expanded) ...[
                const SizedBox(height: 10),
                const Divider(color: AppTheme.borderColor, height: 1),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _detailTag('Linie: ${widget.result.lineCount}'),
                    _detailTag(
                      'Symbole: ${widget.result.presentSymbols.length}/${widget.result.spec.primarySymbols.length}',
                    ),
                    _detailTag(
                      'CODE_MAP: ${widget.result.inCodeMap ? 'TAK' : 'BRAK'}',
                    ),
                    _detailTag(
                      'Ref lib/test: ${widget.result.libReferencesCount}/${widget.result.testReferencesCount}',
                    ),
                  ],
                ),
                if (widget.result.issues.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final issue in widget.result.issues)
                    Text(
                      '• $issue',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.crimsonAlert,
                      ),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Package2AuditButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _Package2AuditButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_Package2AuditButton> createState() => _Package2AuditButtonState();
}

class _Package2AuditButtonState extends State<_Package2AuditButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? AppColors.primaryAccent
            : (_hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.9)
                : AppColors.primaryAccent.withValues(alpha: 0.78)));

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppColors.goldAccent.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Package2AuditToggle extends StatefulWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _Package2AuditToggle({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_Package2AuditToggle> createState() => _Package2AuditToggleState();
}

class _Package2AuditToggleState extends State<_Package2AuditToggle> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? () => widget.onChanged(!widget.value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (widget.value
                      ? AppColors.statusSuccess.withValues(alpha: 0.5)
                      : AppTheme.borderColor),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.value
                    ? Icons.check_box_rounded
                    : Icons.check_box_outline_blank_rounded,
                size: 16,
                color: widget.enabled
                    ? (widget.value
                        ? AppColors.statusSuccess
                        : AppColors.textSecondary)
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: widget.enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Package2FilterChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _Package2FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_Package2FilterChip> createState() => _Package2FilterChipState();
}

class _Package2FilterChipState extends State<_Package2FilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.goldAccent.withValues(alpha: 0.18)
        : (_hovered ? AppColors.surfaceLight : AppColors.surface);
    final border = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? AppColors.goldAccent.withValues(alpha: 0.6)
            : AppTheme.borderColor);

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 14,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                  color: widget.selected
                      ? AppColors.goldAccent
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
