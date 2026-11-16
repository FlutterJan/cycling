// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Kategoria elementu w manifeście Paczki #1 (#163–#212).
enum Package1TaskCategory {
  uiWidget('Widget UI', Icons.widgets_rounded),
  uiScreen('Ekran UI', Icons.desktop_windows_rounded),
  service('Serwis Kariery', Icons.miscellaneous_services_rounded),
  engine3d('Silnik 3D', Icons.view_in_ar_rounded),
  engineAudio('Silnik Audio', Icons.graphic_eq_rounded),
  testSuite('Testy', Icons.verified_rounded),
  diagnostics('Diagnostyka', Icons.health_and_safety_rounded);

  final String label;
  final IconData icon;

  const Package1TaskCategory(this.label, this.icon);
}

/// Poziom ważności wykrytego problemu audytowego.
enum AuditSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const AuditSeverity(this.label, this.color);
}

/// Definicja pojedynczego zadania z Paczki #1 (#163–#212).
@immutable
class Package1TaskSpec {
  final int taskNumber;
  final String filePath;
  final List<String> primarySymbols;
  final Package1TaskCategory category;
  final String description;
  final bool requiresResponsiveLayout;

  const Package1TaskSpec({
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
class AnalyzeIssue {
  final AuditSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const AnalyzeIssue({
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
class FlutterAnalyzeAuditResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final List<AnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const FlutterAnalyzeAuditResult({
    required this.executed,
    required this.exitCode,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.issues,
    required this.rawOutput,
    required this.duration,
  });

  bool get passed => !executed || (exitCode == 0 && errorCount == 0 && warningCount == 0);

  factory FlutterAnalyzeAuditResult.skipped() => const FlutterAnalyzeAuditResult(
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

/// Wynik audytu kompletności pliku `docs/CODE_MAP.md`.
@immutable
class CodeMapAuditResult {
  final bool codeMapExists;
  final int totalLines;
  final int package1CoveredCount;
  final List<String> missingFilePaths;
  final Map<String, List<String>> missingSymbolsByFile;

  const CodeMapAuditResult({
    required this.codeMapExists,
    required this.totalLines,
    required this.package1CoveredCount,
    required this.missingFilePaths,
    required this.missingSymbolsByFile,
  });

  bool get passed =>
      codeMapExists && missingFilePaths.isEmpty && missingSymbolsByFile.isEmpty;

  Map<String, dynamic> toJson() => {
        'codeMapExists': codeMapExists,
        'totalLines': totalLines,
        'package1CoveredCount': package1CoveredCount,
        'missingFilePaths': missingFilePaths,
        'missingSymbolsByFile': missingSymbolsByFile,
        'passed': passed,
      };
}

/// Szczegółowy wynik audytu pojedynczego zadania z Paczki #1.
@immutable
class TaskAuditResult {
  final Package1TaskSpec spec;
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
  final List<String> issues;

  const TaskAuditResult({
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
    required this.issues,
  });

  bool get passed =>
      fileExists &&
      fileSizeBytes > 0 &&
      missingSymbols.isEmpty &&
      todoMarkersCount == 0 &&
      unimplementedThrowsCount == 0 &&
      inCodeMap &&
      issues.isEmpty;

  AuditSeverity get severity {
    if (!fileExists || missingSymbols.isNotEmpty || unimplementedThrowsCount > 0) {
      return AuditSeverity.error;
    }
    if (!inCodeMap || todoMarkersCount > 0 || issues.isNotEmpty) {
      return AuditSeverity.warning;
    }
    if (missingSymbolsInCodeMap.isNotEmpty) {
      return AuditSeverity.info;
    }
    return AuditSeverity.pass;
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
        'issues': issues,
        'passed': passed,
      };
}

/// Pełny raport audytu spójności Paczki #1 (#163–#212).
@immutable
class Package1AuditReport {
  final DateTime generatedAt;
  final String projectRoot;
  final List<TaskAuditResult> taskResults;
  final CodeMapAuditResult codeMapResult;
  final FlutterAnalyzeAuditResult analyzeResult;
  final Duration duration;

  const Package1AuditReport({
    required this.generatedAt,
    required this.projectRoot,
    required this.taskResults,
    required this.codeMapResult,
    required this.analyzeResult,
    required this.duration,
  });

  int get totalTasks => taskResults.length;
  int get passedTasks => taskResults.where((r) => r.passed).length;
  int get failedTasks => totalTasks - passedTasks;
  bool get overallPassed =>
      failedTasks == 0 && codeMapResult.passed && analyzeResult.passed;

  String toMarkdownSummary() {
    final buffer = StringBuffer()
      ..writeln('# Raport Audytu Paczki #1 (#163–#212)')
      ..writeln('- **Data**: ${generatedAt.toIso8601String()}')
      ..writeln('- **Katalog projektu**: `$projectRoot`')
      ..writeln('- **Zadania spójne**: $passedTasks / $totalTasks')
      ..writeln(
        '- **CODE_MAP.md**: ${codeMapResult.passed ? 'KOMPLETNA' : 'BRAKI (${codeMapResult.missingFilePaths.length} plików)'}',
      )
      ..writeln(
        '- **flutter analyze**: ${analyzeResult.executed ? (analyzeResult.passed ? 'CZYSTY (0 błędów)' : '${analyzeResult.errorCount} błędów, ${analyzeResult.warningCount} ostrzeżeń') : 'POMINIĘTO'}',
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
        'analyzeResult': analyzeResult.toJson(),
        'taskResults': taskResults.map((e) => e.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Skrypt i silnik diagnostyczny weryfikujący spójność wszystkich klas z Paczki #1 (#163–#212),
/// czystość `flutter analyze` oraz kompletność wpisów w `docs/CODE_MAP.md`.
class SniperPackage1AuditRunner {
  const SniperPackage1AuditRunner();

  /// Pełny manifest 50 zadań Paczki #1 (#163–#212).
  static const List<Package1TaskSpec> package1Manifest = [
    Package1TaskSpec(
      taskNumber: 163,
      filePath: 'lib/ui/widgets/rider_comparison_side_by_side_modal.dart',
      primarySymbols: ['RiderComparisonSideBySideModal'],
      category: Package1TaskCategory.uiWidget,
      description: 'Modal porównania 2–3 kolarzy obok siebie (W vs W/kg)',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 164,
      filePath: 'lib/services/career/ai_team_transfer_simulation_service.dart',
      primarySymbols: [
        'AiTeamTransferSimulationService',
        'TeamRosterNeedsAnalyzer',
        'TransferNewsItem',
      ],
      category: Package1TaskCategory.service,
      description: 'Symulator rynku transferowego 52 drużyn AI',
    ),
    Package1TaskSpec(
      taskNumber: 165,
      filePath: 'lib/ui/widgets/keyboard_shortcuts_manager.dart',
      primarySymbols: ['KeyboardShortcutsManager', 'ShortcutsCheatSheetOverlay'],
      category: Package1TaskCategory.uiWidget,
      description: 'Menedżer skrótów klawiszowych 3D i Menedżera',
    ),
    Package1TaskSpec(
      taskNumber: 166,
      filePath: 'lib/ui/screens/quick_race_sandbox_screen.dart',
      primarySymbols: ['QuickRaceSandboxScreen'],
      category: Package1TaskCategory.uiScreen,
      description: 'Ekran Szybkiego Wyścigu i Laboratorium Taktycznego 3D',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 167,
      filePath: 'lib/ui/screens/main_title_menu_screen.dart',
      primarySymbols: ['MainTitleMenuScreen', 'AnimatedPelotonBackdropPainter'],
      category: Package1TaskCategory.uiScreen,
      description: 'Ekran tytułowy AAA z animowanym tłem alpejskim',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 168,
      filePath: 'lib/ui/widgets/save_load_slots_modal.dart',
      primarySymbols: ['SaveLoadSlotsModal'],
      category: Package1TaskCategory.uiWidget,
      description: 'Modal slotów zapisu i eksportu/importu JSON',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 169,
      filePath: 'lib/ui/widgets/tactical_radial_command_menu.dart',
      primarySymbols: ['TacticalRadialCommandMenu'],
      category: Package1TaskCategory.uiWidget,
      description: 'Kołowe menu 8 rozkazów taktycznych 3D',
    ),
    Package1TaskSpec(
      taskNumber: 170,
      filePath: 'lib/ui/widgets/live_tv_commentary_ticker.dart',
      primarySymbols: ['LiveTvCommentaryTicker'],
      category: Package1TaskCategory.uiWidget,
      description: 'Pasek komentarza TV na żywo',
    ),
    Package1TaskSpec(
      taskNumber: 171,
      filePath: 'lib/ui/widgets/podium_3d_ceremony_painter.dart',
      primarySymbols: ['Podium3dCeremonyPainter'],
      category: Package1TaskCategory.uiWidget,
      description: 'Animowana ceremonia dekoracji na podium 3D',
    ),
    Package1TaskSpec(
      taskNumber: 172,
      filePath: 'lib/engine/audio/soundscape_mixer_controller.dart',
      primarySymbols: ['SoundscapeMixerController'],
      category: Package1TaskCategory.engineAudio,
      description: '5-kanałowy mikser pejzażu dźwiękowego wyścigu',
    ),
    Package1TaskSpec(
      taskNumber: 173,
      filePath: 'lib/engine/rendering3d/boids_peloton_flocking_solver.dart',
      primarySymbols: ['BoidsPelotonFlockingSolver'],
      category: Package1TaskCategory.engine3d,
      description: 'Solver Boids unikania kolizji dla 176 kolarzy 3D',
    ),
    Package1TaskSpec(
      taskNumber: 174,
      filePath: 'lib/engine/rendering3d/inverse_kinematics_limb_solver.dart',
      primarySymbols: ['InverseKinematicsLimbSolver'],
      category: Package1TaskCategory.engine3d,
      description: 'Dwustawowy analityczny solver IK nóg i rąk',
    ),
    Package1TaskSpec(
      taskNumber: 175,
      filePath: 'lib/engine/rendering3d/projected_planar_shadows_painter.dart',
      primarySymbols: ['ProjectedPlanarShadowsPainter'],
      category: Package1TaskCategory.engine3d,
      description: 'Rzutowanie miękkich cieni planarnych na asfalt',
    ),
    Package1TaskSpec(
      taskNumber: 176,
      filePath: 'lib/engine/rendering3d/wheel_and_drivetrain_rotator.dart',
      primarySymbols: ['WheelAndDrivetrainRotator'],
      category: Package1TaskCategory.engine3d,
      description: 'Animacja kół, korby i wózka przerzutki',
    ),
    Package1TaskSpec(
      taskNumber: 177,
      filePath: 'lib/engine/rendering3d/roadside_banners_and_arches_renderer.dart',
      primarySymbols: ['RoadsideBannersAndArchesRenderer'],
      category: Package1TaskCategory.engine3d,
      description: 'Renderer dmuchanych bram i barierek sponsorów',
    ),
    Package1TaskSpec(
      taskNumber: 178,
      filePath: 'lib/engine/rendering3d/neutral_service_and_medical_cars.dart',
      primarySymbols: ['NeutralServiceAndMedicalCarsController'],
      category: Package1TaskCategory.engine3d,
      description: 'Auta neutralnego serwisu, ambulans i Commissaire Car',
    ),
    Package1TaskSpec(
      taskNumber: 179,
      filePath: 'lib/engine/rendering3d/tv_helicopter_sky_renderer.dart',
      primarySymbols: ['TvHelicopterSkyRenderer'],
      category: Package1TaskCategory.engine3d,
      description: 'Renderer 3D helikoptera TV nad czołem wyścigu',
    ),
    Package1TaskSpec(
      taskNumber: 180,
      filePath: 'lib/engine/rendering3d/alpine_crowd_tunnel_renderer.dart',
      primarySymbols: ['AlpineCrowdTunnelRenderer'],
      category: Package1TaskCategory.engine3d,
      description: 'Efekt Tunelu Kibiców na stromych podjazdach >8%',
    ),
    Package1TaskSpec(
      taskNumber: 181,
      filePath: 'lib/engine/rendering3d/wet_asphalt_reflections_painter.dart',
      primarySymbols: ['WetAsphaltReflectionsPainter'],
      category: Package1TaskCategory.engine3d,
      description: 'Painter mokrego asfaltu, kałuż i odbić',
    ),
    Package1TaskSpec(
      taskNumber: 182,
      filePath: 'lib/engine/rendering3d/cobblestone_vibration_camera_fx.dart',
      primarySymbols: ['CobblestoneVibrationCameraFx'],
      category: Package1TaskCategory.engine3d,
      description: 'Drgania kamery i kurz na sektorach bruku 1★–5★',
    ),
    Package1TaskSpec(
      taskNumber: 183,
      filePath: 'lib/services/career/race_day_pipeline_orchestrator.dart',
      primarySymbols: ['RaceDayPipelineOrchestrator'],
      category: Package1TaskCategory.service,
      description: 'Orkiestrator cyklu życia dnia wyścigowego',
    ),
    Package1TaskSpec(
      taskNumber: 184,
      filePath: 'lib/services/career/roster_uci_compliance_validator.dart',
      primarySymbols: ['RosterUciComplianceValidator'],
      category: Package1TaskCategory.service,
      description: 'Walidator przepisów UCI dla składów i rowerów',
    ),
    Package1TaskSpec(
      taskNumber: 185,
      filePath: 'lib/services/career/post_race_equipment_degradation_service.dart',
      primarySymbols: ['PostRaceEquipmentDegradationService'],
      category: Package1TaskCategory.service,
      description: 'Serwis zużycia sprzętu i kosztów części zamiennych',
    ),
    Package1TaskSpec(
      taskNumber: 186,
      filePath: 'lib/services/career/uci_points_live_ledger_service.dart',
      primarySymbols: ['UciPointsLiveLedgerService'],
      category: Package1TaskCategory.service,
      description: 'Księga punktów UCI na żywo',
    ),
    Package1TaskSpec(
      taskNumber: 187,
      filePath: 'lib/services/career/prize_money_distribution_service.dart',
      primarySymbols: ['PrizeMoneyDistributionService'],
      category: Package1TaskCategory.service,
      description: 'Serwis podziału nagród finansowych',
    ),
    Package1TaskSpec(
      taskNumber: 188,
      filePath: 'lib/services/career/post_stage_morale_and_ego_updater.dart',
      primarySymbols: ['PostStageMoraleAndEgoUpdater'],
      category: Package1TaskCategory.service,
      description: 'Procesor nastrojów i ego po etapie',
    ),
    Package1TaskSpec(
      taskNumber: 189,
      filePath: 'lib/services/career/medical_post_race_trauma_report.dart',
      primarySymbols: ['MedicalPostRaceTraumaReport'],
      category: Package1TaskCategory.service,
      description: 'Generator raportów medycznych RTG/MRI po kraksach',
    ),
    Package1TaskSpec(
      taskNumber: 190,
      filePath: 'lib/ui/widgets/tv_broadcast_lower_third_banner.dart',
      primarySymbols: ['TvBroadcastLowerThirdBanner'],
      category: Package1TaskCategory.uiWidget,
      description: 'Telewizyjna belka dolna w stylu TDF',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 191,
      filePath: 'lib/ui/widgets/tv_climb_gradient_3d_ribbon_hud.dart',
      primarySymbols: ['TvClimbGradient3dRibbonHud'],
      category: Package1TaskCategory.uiWidget,
      description: 'Telewizyjny profil podjazdu 3D w rogu ekranu',
    ),
    Package1TaskSpec(
      taskNumber: 192,
      filePath: 'lib/ui/widgets/tv_echelon_crosswind_radar_hud.dart',
      primarySymbols: ['TvEchelonCrosswindRadarHud'],
      category: Package1TaskCategory.uiWidget,
      description: 'Telewizyjny radar wiatru bocznego i rantów',
    ),
    Package1TaskSpec(
      taskNumber: 193,
      filePath: 'lib/ui/widgets/tv_picture_in_picture_breakaway_cam.dart',
      primarySymbols: ['TvPictureInPictureBreakawayCam'],
      category: Package1TaskCategory.uiWidget,
      description: 'Okienko Picture-in-Picture 3D na ucieczkę',
    ),
    Package1TaskSpec(
      taskNumber: 194,
      filePath: 'lib/ui/widgets/tv_rider_biometrics_telemetry_box.dart',
      primarySymbols: ['TvRiderBiometricsTelemetryBox'],
      category: Package1TaskCategory.uiWidget,
      description: 'Telewizyjne okienko biometryczne EKG/W\'',
    ),
    Package1TaskSpec(
      taskNumber: 195,
      filePath: 'lib/ui/widgets/tv_intermediate_sprint_kom_popup.dart',
      primarySymbols: ['TvIntermediateSprintKomPopup'],
      category: Package1TaskCategory.uiWidget,
      description: 'Wyskakująca tablica premii lotnej i górskiej',
    ),
    Package1TaskSpec(
      taskNumber: 196,
      filePath: 'lib/ui/widgets/tv_itt_split_timer_comparison_hud.dart',
      primarySymbols: ['TvIttSplitTimerComparisonHud'],
      category: Package1TaskCategory.uiWidget,
      description: 'Zegar pomiarowy jazdy na czas ITT/TTT',
    ),
    Package1TaskSpec(
      taskNumber: 197,
      filePath: 'lib/engine/rendering3d/glb_mesh_integrity_validator.dart',
      primarySymbols: ['GlbMeshIntegrityValidator'],
      category: Package1TaskCategory.engine3d,
      description: 'Walidator startowy siatek .glb z fallbackiem w RAM',
    ),
    Package1TaskSpec(
      taskNumber: 198,
      filePath: 'lib/engine/rendering3d/procedural_pbr_texture_atlas_generator.dart',
      primarySymbols: ['ProceduralPbrTextureAtlasGenerator'],
      category: Package1TaskCategory.engine3d,
      description: 'Generator proceduralnego atlasu tekstur PBR w RAM',
    ),
    Package1TaskSpec(
      taskNumber: 199,
      filePath: 'lib/ui/widgets/career_onboarding_interactive_tour.dart',
      primarySymbols: ['CareerOnboardingInteractiveTour'],
      category: Package1TaskCategory.uiWidget,
      description: '5-krokowy samouczek nowego gracza',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 200,
      filePath: 'lib/ui/widgets/global_search_spotlight_modal.dart',
      primarySymbols: ['GlobalSearchSpotlightModal'],
      category: Package1TaskCategory.uiWidget,
      description: 'Globalna wyszukiwarka Spotlight Ctrl+K',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 201,
      filePath: 'lib/ui/widgets/season_calendar_gantt_timeline.dart',
      primarySymbols: ['SeasonCalendarGanttTimeline'],
      category: Package1TaskCategory.uiWidget,
      description: 'Poziomy wykres Gantta sezonu dla 28 kolarzy',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 202,
      filePath: 'lib/ui/widgets/rider_fatigue_body_heatmap_painter.dart',
      primarySymbols: ['RiderFatigueBodyHeatmapPainter'],
      category: Package1TaskCategory.uiWidget,
      description: 'Anatomiczny diagram zmęczenia mięśniowego i CNS',
    ),
    Package1TaskSpec(
      taskNumber: 203,
      filePath: 'lib/ui/widgets/wind_tunnel_cda_delta_comparator.dart',
      primarySymbols: ['WindTunnelCdaDeltaComparator'],
      category: Package1TaskCategory.uiWidget,
      description: 'Komparator delty CdA w Tunelu Aerodynamicznym',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 204,
      filePath: 'lib/ui/widgets/team_budget_cashflow_projection_chart.dart',
      primarySymbols: ['TeamBudgetCashflowProjectionChart'],
      category: Package1TaskCategory.uiWidget,
      description: '12-miesięczny wykres przepływów pieniężnych drużyny',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 205,
      filePath: 'lib/ui/widgets/contract_negotiation_chat_simulator.dart',
      primarySymbols: ['ContractNegotiationChatSimulator'],
      category: Package1TaskCategory.uiWidget,
      description: 'Symulator negocjacji kontraktowych na żywo z agentem',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 206,
      filePath: 'lib/ui/widgets/custom_race_route_elevation_brush.dart',
      primarySymbols: ['CustomRaceRouteElevationBrush'],
      category: Package1TaskCategory.uiWidget,
      description: 'Pędzel rzeźbienia terenu w Kreatorze Etapów',
    ),
    Package1TaskSpec(
      taskNumber: 207,
      filePath: 'test/physics_and_w_prime_unit_test.dart',
      primarySymbols: ['main'],
      category: Package1TaskCategory.testSuite,
      description: 'Testy jednostkowe fizyki i modelu Skiba W\'',
    ),
    Package1TaskSpec(
      taskNumber: 208,
      filePath: 'test/peloton_drafting_and_echelons_test.dart',
      primarySymbols: ['main'],
      category: Package1TaskCategory.testSuite,
      description: 'Testy draftingu i rantów na wietrze bocznym',
    ),
    Package1TaskSpec(
      taskNumber: 209,
      filePath: 'test/career_simulation_full_year_test.dart',
      primarySymbols: ['main'],
      category: Package1TaskCategory.testSuite,
      description: 'Test integracyjny pełnych 365 dni kariery',
    ),
    Package1TaskSpec(
      taskNumber: 210,
      filePath: 'test/ui_responsive_layout_overflow_test.dart',
      primarySymbols: ['main'],
      category: Package1TaskCategory.testSuite,
      description: 'Automatyczny test braku RenderFlex overflow (390/1024/1600)',
    ),
    Package1TaskSpec(
      taskNumber: 211,
      filePath: 'lib/core/diagnostics/memory_and_stream_leak_guard.dart',
      primarySymbols: ['MemoryAndStreamLeakGuard', 'MemoryAndStreamLeakGuardPanel'],
      category: Package1TaskCategory.diagnostics,
      description: 'Strażnik pamięci Isolate, AnimationController i StreamSubscription',
      requiresResponsiveLayout: true,
    ),
    Package1TaskSpec(
      taskNumber: 212,
      filePath: 'lib/core/diagnostics/sniper_package_1_audit_runner.dart',
      primarySymbols: ['SniperPackage1AuditRunner', 'SniperPackage1AuditPanel'],
      category: Package1TaskCategory.diagnostics,
      description: 'Skrypt diagnostyczny spójności Paczki #1 (#163–#212)',
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

  /// Uruchamia pełny audyt Paczki #1 (#163–#212).
  Future<Package1AuditReport> runFullAudit({
    String? projectRoot,
    bool runFlutterAnalyze = true,
    Future<FlutterAnalyzeAuditResult> Function(String root)? customAnalyzeRunner,
  }) async {
    final stopwatch = Stopwatch()..start();
    final root = resolveProjectRoot(projectRoot);
    final codeMapFile = File('$root${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md');
    final codeMapContent = codeMapFile.existsSync() ? codeMapFile.readAsStringSync() : null;

    final taskResults = <TaskAuditResult>[
      for (final spec in package1Manifest)
        auditSingleTask(
          spec,
          projectRoot: root,
          codeMapContent: codeMapContent,
        ),
    ];

    final codeMapResult = auditCodeMap(
      projectRoot: root,
      codeMapContent: codeMapContent,
    );

    final analyzeResult = runFlutterAnalyze
        ? await (customAnalyzeRunner != null
            ? customAnalyzeRunner(root)
            : runFlutterAnalyzeProcess(root))
        : FlutterAnalyzeAuditResult.skipped();

    stopwatch.stop();
    return Package1AuditReport(
      generatedAt: DateTime.now(),
      projectRoot: root,
      taskResults: taskResults,
      codeMapResult: codeMapResult,
      analyzeResult: analyzeResult,
      duration: stopwatch.elapsed,
    );
  }

  /// Audytuje pojedynczy plik z manifestu Paczki #1.
  TaskAuditResult auditSingleTask(
    Package1TaskSpec spec, {
    required String projectRoot,
    String? codeMapContent,
  }) {
    final normalizedRelative = spec.filePath.replaceAll('/', Platform.pathSeparator);
    final file = File('$projectRoot${Platform.pathSeparator}$normalizedRelative');
    final issues = <String>[];

    if (!file.existsSync()) {
      issues.add('Brak pliku na dysku: ${spec.filePath}');
      return TaskAuditResult(
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

    final todoRegex = RegExp(r'^\s*//\s*(TODO|FIXME)\b', caseSensitive: false, multiLine: true);
    final unimplementedRegex = RegExp(r'\bthrow\s+UnimplementedError\s*\(');
    final todoCount = todoRegex.allMatches(content).length;
    final unimplementedCount = unimplementedRegex.allMatches(content).length;

    if (todoCount > 0) {
      issues.add('Wykryto niedokończone znaczniki TODO/FIXME ($todoCount)');
    }
    if (unimplementedCount > 0) {
      issues.add('Wykryto UnimplementedError ($unimplementedCount)');
    }

    final inCodeMap = codeMapContent != null && codeMapContent.contains(spec.filePath);
    if (!inCodeMap) {
      issues.add('Brak wpisu w docs/CODE_MAP.md');
    }

    final missingCodeMapSymbols = <String>[];
    if (codeMapContent != null && spec.category != Package1TaskCategory.testSuite) {
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

    return TaskAuditResult(
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
      issues: issues,
    );
  }

  /// Weryfikuje kompletność wpisów dla Paczki #1 w `docs/CODE_MAP.md`.
  CodeMapAuditResult auditCodeMap({
    required String projectRoot,
    String? codeMapContent,
    List<Package1TaskSpec>? manifest,
  }) {
    final effectiveManifest = manifest ?? package1Manifest;
    final codeMapFile =
        File('$projectRoot${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md');
    final exists = codeMapContent != null || codeMapFile.existsSync();
    if (!exists) {
      return CodeMapAuditResult(
        codeMapExists: false,
        totalLines: 0,
        package1CoveredCount: 0,
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
      if (spec.category != Package1TaskCategory.testSuite) {
        final missingSym = spec.primarySymbols
            .where((sym) => !content.contains(sym))
            .toList();
        if (missingSym.isNotEmpty) {
          missingSymbolsByFile[spec.filePath] = missingSym;
        }
      }
    }

    return CodeMapAuditResult(
      codeMapExists: true,
      totalLines: totalLines,
      package1CoveredCount: covered,
      missingFilePaths: missingFilePaths,
      missingSymbolsByFile: missingSymbolsByFile,
    );
  }

  /// Uruchamia `flutter analyze` w katalogu projektu i parsuje wyniki.
  Future<FlutterAnalyzeAuditResult> runFlutterAnalyzeProcess(
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

      final errors = issues.where((i) => i.severity == AuditSeverity.error).length;
      final warnings = issues.where((i) => i.severity == AuditSeverity.warning).length;
      final infos = issues.where((i) => i.severity == AuditSeverity.info).length;

      return FlutterAnalyzeAuditResult(
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
      return FlutterAnalyzeAuditResult(
        executed: true,
        exitCode: -1,
        errorCount: 1,
        warningCount: 0,
        infoCount: 0,
        issues: [
          AnalyzeIssue(
            severity: AuditSeverity.error,
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

  /// Parsuje standardowe linie wyjścia `flutter analyze` (format `severity • message • file:line:col • rule`).
  static List<AnalyzeIssue> parseFlutterAnalyzeOutput(String output) {
    final issues = <AnalyzeIssue>[];
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
        'error' => AuditSeverity.error,
        'warning' => AuditSeverity.warning,
        _ => AuditSeverity.info,
      };
      issues.add(
        AnalyzeIssue(
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
}

/// Stan kontrolera audytu Paczki #1 w Riverpod.
@immutable
class SniperPackage1AuditState {
  final bool isRunning;
  final Package1AuditReport? report;
  final String? errorMessage;
  final Package1TaskCategory? selectedCategory;
  final bool onlyFailures;
  final String searchQuery;

  const SniperPackage1AuditState({
    this.isRunning = false,
    this.report,
    this.errorMessage,
    this.selectedCategory,
    this.onlyFailures = false,
    this.searchQuery = '',
  });

  SniperPackage1AuditState copyWith({
    bool? isRunning,
    Package1AuditReport? report,
    String? errorMessage,
    bool clearError = false,
    Package1TaskCategory? selectedCategory,
    bool clearCategory = false,
    bool? onlyFailures,
    String? searchQuery,
  }) {
    return SniperPackage1AuditState(
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      onlyFailures: onlyFailures ?? this.onlyFailures,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<TaskAuditResult> get filteredResults {
    final results = report?.taskResults ?? const <TaskAuditResult>[];
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

/// Notifier zarządzający wykonywaniem i filtrowaniem audytu Paczki #1.
class SniperPackage1AuditNotifier extends StateNotifier<SniperPackage1AuditState> {
  final SniperPackage1AuditRunner _runner;
  final String? _projectRoot;

  SniperPackage1AuditNotifier({
    SniperPackage1AuditRunner runner = const SniperPackage1AuditRunner(),
    String? projectRoot,
  })  : _runner = runner,
        _projectRoot = projectRoot,
        super(const SniperPackage1AuditState());

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
        errorMessage: 'Błąd audytu Paczki #1: $e',
      );
    }
  }

  void setCategoryFilter(Package1TaskCategory? category) {
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

/// Globalny provider audytu Paczki #1 (#163–#212).
final sniperPackage1AuditProvider = StateNotifierProvider.autoDispose<
    SniperPackage1AuditNotifier, SniperPackage1AuditState>(
  (ref) => SniperPackage1AuditNotifier(),
);

/// Responsywny panel UI prezentujący wyniki audytu spójności Paczki #1 (#163–#212).
class SniperPackage1AuditPanel extends ConsumerStatefulWidget {
  final String? projectRoot;
  final bool autoRunOnInit;
  final bool includeFlutterAnalyzeByDefault;

  const SniperPackage1AuditPanel({
    super.key,
    this.projectRoot,
    this.autoRunOnInit = false,
    this.includeFlutterAnalyzeByDefault = false,
  });

  @override
  ConsumerState<SniperPackage1AuditPanel> createState() =>
      _SniperPackage1AuditPanelState();
}

class _SniperPackage1AuditPanelState
    extends ConsumerState<SniperPackage1AuditPanel> {
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
            .read(sniperPackage1AuditProvider.notifier)
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
    final state = ref.watch(sniperPackage1AuditProvider);
    final notifier = ref.read(sniperPackage1AuditProvider.notifier);

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
    SniperPackage1AuditState state,
    SniperPackage1AuditNotifier notifier,
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
                Icons.fact_check_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Audyt Spójności Paczki #1 (#163–#212)',
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
          'Weryfikacja klas Dart, wpisów w docs/CODE_MAP.md oraz czystości flutter analyze.',
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
        _InteractiveAuditToggle(
          label: 'flutter analyze',
          value: _includeFlutterAnalyze,
          enabled: !state.isRunning,
          onChanged: (v) => setState(() => _includeFlutterAnalyze = v),
        ),
        _InteractiveAuditButton(
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
    Package1AuditReport? report,
    bool isCompact,
    bool isMedium,
  ) {
    final cards = [
      _AuditKpiCard(
        title: 'Zadania #163–#212',
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
      _AuditKpiCard(
        title: 'docs/CODE_MAP.md',
        value: report == null
            ? '—'
            : '${report.codeMapResult.package1CoveredCount} / 50',
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
      _AuditKpiCard(
        title: 'flutter analyze',
        value: report == null
            ? '—'
            : (report.analyzeResult.executed
                ? '${report.analyzeResult.errorCount}E / ${report.analyzeResult.warningCount}W'
                : 'Pominięto'),
        subtitle: report == null
            ? 'Analiza statyczna'
            : (report.analyzeResult.passed
                ? 'Czysty wynik analizy'
                : 'Wykryto problemy lintera'),
        accent: report == null
            ? AppColors.textSecondary
            : (report.analyzeResult.passed
                ? AppColors.statusSuccess
                : AppColors.crimsonAlert),
        icon: Icons.code_rounded,
      ),
      _AuditKpiCard(
        title: 'Czas wykonania',
        value: report == null ? '—' : '${report.duration.inMilliseconds} ms',
        subtitle: report == null
            ? 'Tryb Snajpera'
            : (report.overallPassed ? 'STATUS: PASS' : 'STATUS: FAIL'),
        accent: report == null
            ? AppColors.goldAccent
            : (report.overallPassed
                ? AppColors.goldAccent
                : AppColors.crimsonAlert),
        icon: Icons.speed_rounded,
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
    SniperPackage1AuditState state,
    SniperPackage1AuditNotifier notifier,
    bool isCompact,
  ) {
    final searchField = SizedBox(
      width: isCompact ? double.infinity : 260,
      child: TextField(
        controller: _searchController,
        onChanged: notifier.setSearchQuery,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Szukaj #numer, klasy lub pliku...',
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: AppColors.surface,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      ),
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _InteractiveFilterChip(
          label: 'Tylko błędy',
          selected: state.onlyFailures,
          accent: AppColors.crimsonAlert,
          onTap: () => notifier.setOnlyFailures(!state.onlyFailures),
        ),
        for (final cat in Package1TaskCategory.values)
          _InteractiveFilterChip(
            label: cat.label,
            selected: state.selectedCategory == cat,
            accent: AppColors.goldAccent,
            onTap: () => notifier.setCategoryFilter(cat),
          ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 10),
          chips,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        searchField,
        const SizedBox(width: 12),
        Expanded(child: chips),
      ],
    );
  }

  Widget _buildResultsList(SniperPackage1AuditState state, bool isCompact) {
    if (state.report == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.radar_rounded,
              color: AppColors.goldAccent,
              size: 32,
            ),
            SizedBox(height: 10),
            Text(
              'Kliknij „Uruchom Audyt”, aby zweryfikować 50 modułów Paczki #1.',
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
          'Brak wyników spełniających wybrane kryteria filtrowania.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 440),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final item = items[index];
          final expanded = _expandedTasks.contains(item.spec.taskNumber);
          return _TaskAuditRowCard(
            result: item,
            expanded: expanded,
            isCompact: isCompact,
            onToggleExpand: () {
              setState(() {
                if (expanded) {
                  _expandedTasks.remove(item.spec.taskNumber);
                } else {
                  _expandedTasks.add(item.spec.taskNumber);
                }
              });
            },
          );
        },
      ),
    );
  }
}

class _AuditKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _AuditKpiCard({
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
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
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
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
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
        ],
      ),
    );
  }
}

class _InteractiveAuditButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveAuditButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveAuditButton> createState() =>
      _InteractiveAuditButtonState();
}

class _InteractiveAuditButtonState extends State<_InteractiveAuditButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? AppColors.primaryAccent.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.primaryAccent.withValues(alpha: 0.92)
                : AppColors.primaryAccent;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : AppColors.goldAccent.withValues(alpha: 0.45),
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 18,
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
      ),
    );
  }
}

class _InteractiveAuditToggle extends StatefulWidget {
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _InteractiveAuditToggle({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_InteractiveAuditToggle> createState() =>
      _InteractiveAuditToggleState();
}

class _InteractiveAuditToggleState extends State<_InteractiveAuditToggle> {
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
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.value
                        ? AppColors.statusSuccess.withValues(alpha: 0.6)
                        : AppTheme.borderColor),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.value
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: widget.value
                      ? AppColors.statusSuccess
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.selected
                  ? widget.accent.withValues(alpha: 0.18)
                  : (_hovered ? AppColors.surfaceLight : AppColors.surface),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.selected ? widget.accent : AppTheme.borderColor),
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
                color: widget.selected ? widget.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TaskAuditRowCard extends StatefulWidget {
  final TaskAuditResult result;
  final bool expanded;
  final bool isCompact;
  final VoidCallback onToggleExpand;

  const _TaskAuditRowCard({
    required this.result,
    required this.expanded,
    required this.isCompact,
    required this.onToggleExpand,
  });

  @override
  State<_TaskAuditRowCard> createState() => _TaskAuditRowCardState();
}

class _TaskAuditRowCardState extends State<_TaskAuditRowCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final severity = widget.result.severity;
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onToggleExpand,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (widget.result.passed
                        ? AppTheme.borderColor
                        : severity.color.withValues(alpha: 0.55)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
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
                            widget.result.spec.primarySymbols.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
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
                      const SizedBox(width: 8),
                      Text(
                        '${widget.result.lineCount} linii',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
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
                      size: 18,
                    ),
                  ],
                ),
                if (widget.expanded) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  const SizedBox(height: 10),
                  Text(
                    widget.result.spec.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _DetailBadge(
                        label: widget.result.inCodeMap
                            ? 'CODE_MAP: OK'
                            : 'CODE_MAP: BRAK',
                        color: widget.result.inCodeMap
                            ? AppColors.statusSuccess
                            : AppColors.crimsonAlert,
                      ),
                      _DetailBadge(
                        label: 'TODO: ${widget.result.todoMarkersCount}',
                        color: widget.result.todoMarkersCount == 0
                            ? AppColors.statusSuccess
                            : AppColors.amberWarning,
                      ),
                      if (widget.result.spec.requiresResponsiveLayout)
                        _DetailBadge(
                          label: widget.result.hasResponsiveLayout
                              ? 'LayoutBuilder: OK'
                              : 'LayoutBuilder: BRAK',
                          color: widget.result.hasResponsiveLayout
                              ? AppColors.statusSuccess
                              : AppColors.amberWarning,
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
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
