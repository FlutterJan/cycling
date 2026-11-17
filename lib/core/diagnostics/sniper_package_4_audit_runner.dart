// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Kategoria elementu w manifeście Paczki #4 (#313–#362).
enum Package4TaskCategory {
  models('Modele Danych', Icons.storage_rounded),
  physics('Fizyka i Fizjologia', Icons.speed_rounded),
  pelotonAi('Taktyka i AI Peletonu', Icons.groups_rounded),
  engine3d('Silnik 3D i Kamery', Icons.view_in_ar_rounded),
  service('Serwisy Kariery', Icons.miscellaneous_services_rounded),
  uiWidget('Widgety UI / HUD', Icons.widgets_rounded),
  uiScreen('Ekrany UI', Icons.desktop_windows_rounded),
  testSuite('Testy Jednostkowe/Widgetowe', Icons.verified_rounded),
  diagnostics('Diagnostyka i Routing', Icons.health_and_safety_rounded);

  final String label;
  final IconData icon;

  const Package4TaskCategory(this.label, this.icon);
}

/// Poziom ważności wykrytego problemu w audycie Paczki #4.
enum Package4AuditSeverity {
  pass('OK', AppColors.statusSuccess),
  info('Info', AppColors.accentBlue),
  warning('Ostrzeżenie', AppColors.amberWarning),
  error('Błąd', AppColors.crimsonAlert);

  final String label;
  final Color color;

  const Package4AuditSeverity(this.label, this.color);
}

/// Definicja pojedynczego zadania z Paczki #4 (#313–#362).
@immutable
class Package4TaskSpec {
  final int taskNumber;
  final String filePath;
  final List<String> primarySymbols;
  final Package4TaskCategory category;
  final String description;
  final bool requiresResponsiveLayout;

  const Package4TaskSpec({
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
class Package4AnalyzeIssue {
  final Package4AuditSeverity severity;
  final String message;
  final String filePath;
  final int line;
  final int column;
  final String ruleName;

  const Package4AnalyzeIssue({
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
class Package4FlutterAnalyzeResult {
  final bool executed;
  final int exitCode;
  final int errorCount;
  final int warningCount;
  final int infoCount;
  final List<Package4AnalyzeIssue> issues;
  final String rawOutput;
  final Duration duration;

  const Package4FlutterAnalyzeResult({
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

  factory Package4FlutterAnalyzeResult.skipped() =>
      const Package4FlutterAnalyzeResult(
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

/// Wynik uruchomienia testów jednostkowych i widgetowych `flutter test`.
@immutable
class Package4FlutterTestResult {
  final bool executed;
  final int exitCode;
  final int totalPassed;
  final int totalFailed;
  final int totalSkipped;
  final List<String> failedTestNames;
  final List<String> executedTargets;
  final String rawOutput;
  final Duration duration;

  const Package4FlutterTestResult({
    required this.executed,
    required this.exitCode,
    required this.totalPassed,
    required this.totalFailed,
    required this.totalSkipped,
    required this.failedTestNames,
    required this.executedTargets,
    required this.rawOutput,
    required this.duration,
  });

  bool get passed =>
      !executed || (exitCode == 0 && totalFailed == 0 && totalPassed > 0);

  factory Package4FlutterTestResult.skipped() =>
      const Package4FlutterTestResult(
        executed: false,
        exitCode: 0,
        totalPassed: 0,
        totalFailed: 0,
        totalSkipped: 0,
        failedTestNames: [],
        executedTargets: [],
        rawOutput: 'Pominięto uruchomienie procesu flutter test.',
        duration: Duration.zero,
      );

  Map<String, dynamic> toJson() => {
        'executed': executed,
        'exitCode': exitCode,
        'totalPassed': totalPassed,
        'totalFailed': totalFailed,
        'totalSkipped': totalSkipped,
        'passed': passed,
        'durationMs': duration.inMilliseconds,
        'failedTestNames': failedTestNames,
        'executedTargets': executedTargets,
      };
}

/// Wynik audytu kompletności pliku `docs/CODE_MAP.md` dla Paczki #4.
@immutable
class Package4CodeMapAuditResult {
  final bool codeMapExists;
  final int totalLines;
  final int package4CoveredCount;
  final List<String> missingFilePaths;
  final Map<String, List<String>> missingSymbolsByFile;

  const Package4CodeMapAuditResult({
    required this.codeMapExists,
    required this.totalLines,
    required this.package4CoveredCount,
    required this.missingFilePaths,
    required this.missingSymbolsByFile,
  });

  bool get passed =>
      codeMapExists && missingFilePaths.isEmpty && missingSymbolsByFile.isEmpty;

  Map<String, dynamic> toJson() => {
        'codeMapExists': codeMapExists,
        'totalLines': totalLines,
        'package4CoveredCount': package4CoveredCount,
        'missingFilePaths': missingFilePaths,
        'missingSymbolsByFile': missingSymbolsByFile,
        'passed': passed,
      };
}

/// Wynik audytu integracji Paczki #4 z resztą gry (mosty, importy, referencje).
@immutable
class Package4IntegrationCheckResult {
  final int totalScannedLibFiles;
  final int totalScannedTestFiles;
  final List<String> verifiedCoreBridges;
  final List<String> missingCoreBridges;
  final Map<String, List<String>> brokenRelativeImportsByFile;
  final int integratedTasksCount;
  final int totalIntegrableTasksCount;

  const Package4IntegrationCheckResult({
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

/// Szczegółowy wynik audytu pojedynczego zadania z Paczki #4.
@immutable
class Package4TaskAuditResult {
  final Package4TaskSpec spec;
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

  const Package4TaskAuditResult({
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

  Package4AuditSeverity get severity {
    if (!fileExists ||
        missingSymbols.isNotEmpty ||
        unimplementedThrowsCount > 0 ||
        brokenRelativeImports.isNotEmpty) {
      return Package4AuditSeverity.error;
    }
    if (!inCodeMap || todoMarkersCount > 0 || issues.isNotEmpty) {
      return Package4AuditSeverity.warning;
    }
    if (missingSymbolsInCodeMap.isNotEmpty) {
      return Package4AuditSeverity.info;
    }
    return Package4AuditSeverity.pass;
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

/// Pełny raport audytu integracji i spójności Paczki #4 (#313–#362).
@immutable
class Package4AuditReport {
  final DateTime generatedAt;
  final String projectRoot;
  final List<Package4TaskAuditResult> taskResults;
  final Package4CodeMapAuditResult codeMapResult;
  final Package4IntegrationCheckResult integrationResult;
  final Package4FlutterAnalyzeResult analyzeResult;
  final Package4FlutterTestResult testResult;
  final Duration duration;

  const Package4AuditReport({
    required this.generatedAt,
    required this.projectRoot,
    required this.taskResults,
    required this.codeMapResult,
    required this.integrationResult,
    required this.analyzeResult,
    required this.testResult,
    required this.duration,
  });

  int get totalTasks => taskResults.length;
  int get passedTasks => taskResults.where((r) => r.passed).length;
  int get failedTasks => totalTasks - passedTasks;
  bool get overallPassed =>
      failedTasks == 0 &&
      codeMapResult.passed &&
      integrationResult.passed &&
      analyzeResult.passed &&
      testResult.passed;

  String toMarkdownSummary() {
    final buffer = StringBuffer()
      ..writeln('# Raport Audytu Integracji Paczki #4 (#313–#362)')
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
      ..writeln(
        '- **flutter test**: ${testResult.executed ? (testResult.passed ? 'ZALICZONE (${testResult.totalPassed} testów)' : '${testResult.totalFailed} niezaliczonych / ${testResult.totalPassed} zaliczonych') : 'POMINIĘTO'}',
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
        'testResult': testResult.toJson(),
        'taskResults': taskResults.map((e) => e.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Skrypt i silnik audytowy weryfikujący kompletną integrację Paczki #4 (#313–#362),
/// uruchamiający testy jednostkowe/widgetowe oraz potwierdzający zero błędów w `flutter analyze`.
class SniperPackage4AuditRunner {
  const SniperPackage4AuditRunner();

  /// Kluczowe punkty integracji w grze, z którymi łączą się moduły Paczki #4.
  static const List<String> coreIntegrationBridges = [
    'lib/core/router/app_router.dart',
    'lib/core/diagnostics/save_compatibility_v4_migrator.dart',
    'lib/engine/engine_integration_bridge.dart',
    'lib/engine/rendering3d/peloton_3d_canvas_engine.dart',
    'lib/engine/simulation/stage_replay_recorder.dart',
    'lib/ui/screens/main_shell_screen.dart',
  ];

  /// Domyślny pakiet testów jednostkowych i widgetowych Paczki #4.
  static const List<String> package4TestTargets = [
    'test/be_a_pro_career_and_ds_orders_test.dart',
    'test/cyclocross_mud_and_bunnyhop_test.dart',
    'test/velodrome_hour_record_physics_test.dart',
    'test/pedal_biomechanics_and_hydrogel_test.dart',
    'test/first_person_cockpit_and_holo_card_test.dart',
    'test/core/save_compatibility_v4_migrator_test.dart',
    'test/core/sniper_package_4_audit_runner_test.dart',
  ];

  /// Pełny manifest 50 zadań Paczki #4 (#313–#362).
  static const List<Package4TaskSpec> package4Manifest = [
    Package4TaskSpec(
      taskNumber: 313,
      filePath: 'lib/models/career/pro_cyclist_career_state.dart',
      primarySymbols: ['ProCyclistCareerState'],
      category: Package4TaskCategory.models,
      description: 'Model danych kariery pojedynczego kolarza „Zostań Legendą”',
    ),
    Package4TaskSpec(
      taskNumber: 314,
      filePath: 'lib/ui/screens/be_a_pro_character_creator_screen.dart',
      primarySymbols: ['BeAProCharacterCreatorScreen'],
      category: Package4TaskCategory.uiScreen,
      description: 'Ekran kreatora własnego kolarza Be a Pro z podglądem 3D',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 315,
      filePath:
          'lib/engine/rendering3d/first_person_cockpit_camera_renderer.dart',
      primarySymbols: ['FirstPersonCockpitCameraRenderer'],
      category: Package4TaskCategory.engine3d,
      description: 'Widok z pierwszej osoby 3D (Pro Cyclist Cockpit Camera)',
    ),
    Package4TaskSpec(
      taskNumber: 316,
      filePath:
          'lib/engine/peloton/direct_player_rider_steering_controller.dart',
      primarySymbols: ['DirectPlayerRiderSteeringController'],
      category: Package4TaskCategory.pelotonAi,
      description: 'Bezpośrednie sterowanie pojedynczym kolarzem (W/A/S/D, Shift, Spacja)',
    ),
    Package4TaskSpec(
      taskNumber: 317,
      filePath: 'lib/services/career/ds_team_orders_mission_generator.dart',
      primarySymbols: ['DsTeamOrdersMissionGenerator'],
      category: Package4TaskCategory.service,
      description: 'Generator dynamicznych misji i rozkazów DS w trybie Be a Pro',
    ),
    Package4TaskSpec(
      taskNumber: 318,
      filePath: 'lib/ui/widgets/be_a_pro_ds_objective_hud_tracker.dart',
      primarySymbols: ['BeAProDsObjectiveHudTracker'],
      category: Package4TaskCategory.uiWidget,
      description: 'HUD rozkazu Dyrektora Sportowego i kierunku lidera w 3D',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 319,
      filePath: 'lib/services/career/pro_cyclist_lifestyle_and_wealth_service.dart',
      primarySymbols: ['ProCyclistLifestyleAndWealthService'],
      category: Package4TaskCategory.service,
      description: 'System rezydencji, stylu życia i inwestycji kolarza Be a Pro',
    ),
    Package4TaskSpec(
      taskNumber: 320,
      filePath: 'lib/ui/screens/be_a_pro_dashboard_and_apartment_screen.dart',
      primarySymbols: ['BeAProDashboardAndApartmentScreen'],
      category: Package4TaskCategory.uiScreen,
      description: 'Główny ekran apartamentu, rozwoju XP i SMS-ów w Be a Pro',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 321,
      filePath: 'lib/models/race/cyclocross_course_and_mud_model.dart',
      primarySymbols: ['CyclocrossCourseAndMudModel'],
      category: Package4TaskCategory.models,
      description: 'Model trasy zimowego kolarstwa przełajowego CX i błota',
    ),
    Package4TaskSpec(
      taskNumber: 322,
      filePath: 'lib/engine/physics/cyclocross_bunnyhop_and_carry_solver.dart',
      primarySymbols: ['CyclocrossBunnyhopAndCarrySolver'],
      category: Package4TaskCategory.physics,
      description: 'Fizyka przełajowa CX: Dismount & Run oraz skoki Bunny-Hop',
    ),
    Package4TaskSpec(
      taskNumber: 323,
      filePath: 'lib/engine/peloton/cx_pit_bike_exchange_mechanics.dart',
      primarySymbols: ['CxPitBikeExchangeMechanics'],
      category: Package4TaskCategory.pelotonAi,
      description: 'Oblepianie roweru błotem i 4.5-sekundowa wymiana w Pit Lane',
    ),
    Package4TaskSpec(
      taskNumber: 324,
      filePath:
          'lib/engine/rendering3d/cyclocross_3d_arena_and_barriers_renderer.dart',
      primarySymbols: ['Cyclocross3dArenaAndBarriersRenderer'],
      category: Package4TaskCategory.engine3d,
      description: 'Renderer 3D areny przełajowej CX (belki, piasek, boksy)',
    ),
    Package4TaskSpec(
      taskNumber: 325,
      filePath: 'lib/ui/screens/cyclocross_winter_series_screen.dart',
      primarySymbols: ['CyclocrossWinterSeriesScreen'],
      category: Package4TaskCategory.uiScreen,
      description: 'Ekran Zimowego Pucharu Przełajowego CX (8 wyścigów)',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 326,
      filePath: 'lib/models/race/velodrome_track_and_hour_record_model.dart',
      primarySymbols: ['VelodromeTrackAndHourRecordModel'],
      category: Package4TaskCategory.models,
      description: 'Model krytego welodromu 250 m, ostrego koła i Rekordu Godzinnego UCI',
    ),
    Package4TaskSpec(
      taskNumber: 327,
      filePath:
          'lib/engine/physics/velodrome_banking_and_centripetal_solver.dart',
      primarySymbols: ['VelodromeBankingAndCentripetalSolver'],
      category: Package4TaskCategory.physics,
      description: 'Fizyka wirażu 42°–45°, przeciążenia odśrodkowego i tempa na welodromie',
    ),
    Package4TaskSpec(
      taskNumber: 328,
      filePath:
          'lib/engine/rendering3d/velodrome_wooden_bowl_3d_renderer.dart',
      primarySymbols: ['VelodromeWoodenBowl3dRenderer'],
      category: Package4TaskCategory.engine3d,
      description: 'Renderer 3D drewnianego welodromu z laserem wirtualnego rekordu',
    ),
    Package4TaskSpec(
      taskNumber: 329,
      filePath: 'lib/ui/screens/uci_hour_record_attempt_screen.dart',
      primarySymbols: ['UciHourRecordAttemptScreen'],
      category: Package4TaskCategory.uiScreen,
      description: 'Ekran oficjalnej Próby Bicia Rekordu Godzinnego UCI',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 330,
      filePath: 'lib/engine/physics/pedal_stroke_biomechanics_analyzer.dart',
      primarySymbols: ['PedalStrokeBiomechanicsAnalyzer'],
      category: Package4TaskCategory.physics,
      description: 'Analizator biomechaniki obrotu korby 360° (L/R, TE%, PS%)',
    ),
    Package4TaskSpec(
      taskNumber: 331,
      filePath: 'lib/ui/widgets/polar_pedal_force_diagram_painter.dart',
      primarySymbols: ['PolarPedalForceDiagramPainter'],
      category: Package4TaskCategory.uiWidget,
      description: 'Wykres kołowy (Polar View / Peanut Diagram) siły nacisku 0°–360°',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 332,
      filePath: 'lib/ui/widgets/collectible_pro_rider_holo_card.dart',
      primarySymbols: ['CollectibleProRiderHoloCard'],
      category: Package4TaskCategory.uiWidget,
      description: 'Kolekcjonerska karta gwiazdy kolarstwa z holograficznym połyskiem',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 333,
      filePath: 'lib/ui/screens/legends_card_album_and_packs_screen.dart',
      primarySymbols: ['LegendsCardAlbumAndPacksScreen'],
      category: Package4TaskCategory.uiScreen,
      description: 'Album Kart Kolekcjonerskich i Złote Paczki Mistrzowskie',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 334,
      filePath: 'lib/engine/peloton/team_bus_pre_race_speech_buffs.dart',
      primarySymbols: ['TeamBusPreRaceSpeechBuffs'],
      category: Package4TaskCategory.pelotonAi,
      description: 'Odprawa motywacyjna w autobusie drużyny i modyfikatory stresu',
    ),
    Package4TaskSpec(
      taskNumber: 335,
      filePath: 'lib/ui/widgets/team_bus_interior_briefing_modal.dart',
      primarySymbols: ['TeamBusInteriorBriefingModal'],
      category: Package4TaskCategory.uiWidget,
      description: 'Modal wnętrza autobusu zespołu przed startem etapu',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 336,
      filePath: 'lib/engine/events/road_hazards_and_spectator_incidents.dart',
      primarySymbols: ['RoadHazardsAndSpectatorincidents'],
      category: Package4TaskCategory.pelotonAi,
      description: 'Incydenty drogowe: wysepki, przejazdy kolejowe, kibice, plamy oleju',
    ),
    Package4TaskSpec(
      taskNumber: 337,
      filePath:
          'lib/engine/rendering3d/traffic_islands_and_railway_3d_renderer.dart',
      primarySymbols: ['TrafficIslandsAndRailway3dRenderer'],
      category: Package4TaskCategory.engine3d,
      description: 'Renderer 3D wysepek, progów, przejazdów kolejowych i sędziów moto',
    ),
    Package4TaskSpec(
      taskNumber: 338,
      filePath: 'lib/services/career/testimonial_farewell_race_service.dart',
      primarySymbols: ['TestimonialFarewellRaceService'],
      category: Package4TaskCategory.service,
      description: 'Pożegnalny sezon legend >=36 lat, szpaler i przejście na DS',
    ),
    Package4TaskSpec(
      taskNumber: 339,
      filePath: 'lib/services/career/custom_jersey_sponsor_patch_placer.dart',
      primarySymbols: ['CustomJerseySponsorPatchPlacer'],
      category: Package4TaskCategory.service,
      description: 'Rozmieszczacz logotypów sponsorów na koszulkach z dziedziczeniem 3D',
    ),
    Package4TaskSpec(
      taskNumber: 340,
      filePath:
          'lib/engine/physics/carbohydrate_hydrogel_and_ketones_engine.dart',
      primarySymbols: ['CarbohydrateHydrogelAndKetonesEngine'],
      category: Package4TaskCategory.physics,
      description: 'Suplementacja WorldTour: hydrożel 110g/h, dwuwęglan sodu i ketony',
    ),
    Package4TaskSpec(
      taskNumber: 341,
      filePath: 'lib/ui/widgets/nutrition_strategy_planner_panel.dart',
      primarySymbols: ['NutritionStrategyplannerPanel'],
      category: Package4TaskCategory.uiWidget,
      description: 'Panel planowania strategii żywieniowej i tolerancji GI',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 342,
      filePath: 'lib/engine/peloton/finish_line_bike_throw_physics.dart',
      primarySymbols: ['FinishLineBikeThrowPhysics'],
      category: Package4TaskCategory.pelotonAi,
      description: 'Fizyka rzutu rowerem na kreskę (Bike Throw +18–28 cm)',
    ),
    Package4TaskSpec(
      taskNumber: 343,
      filePath: 'lib/ui/widgets/bike_throw_timing_minigame_overlay.dart',
      primarySymbols: ['BikeThrowTimingMinigameOverlay'],
      category: Package4TaskCategory.uiWidget,
      description: 'Nakładka minigry wyczucia czasu rzutu rowerem na ostatnich 150 m',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 344,
      filePath:
          'lib/services/career/world_records_and_strava_kom_segments.dart',
      primarySymbols: ['WorldRecordsAndStravaKomSegments'],
      category: Package4TaskCategory.service,
      description: 'Wirtualne segmenty KOM na podjazdach i sektorach bruku',
    ),
    Package4TaskSpec(
      taskNumber: 345,
      filePath:
          'lib/ui/widgets/live_strava_segment_ghost_comparison_hud.dart',
      primarySymbols: ['LiveStravaSegmentGhostComparisonHud'],
      category: Package4TaskCategory.uiWidget,
      description: 'Widżet HUD porównania na żywo z duchem Rekordu Trasy KOM',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 346,
      filePath: 'lib/engine/rendering3d/ghost_rider_hologram_3d_renderer.dart',
      primarySymbols: ['GhostRiderHologram3dRenderer'],
      category: Package4TaskCategory.engine3d,
      description: 'Złoty hologram 3D rekordzisty trasy w ITT, welodromie i KOM',
    ),
    Package4TaskSpec(
      taskNumber: 347,
      filePath:
          'lib/services/career/custom_team_sponsor_storyline_generator.dart',
      primarySymbols: ['CustomTeamSponsorStorylineGenerator'],
      category: Package4TaskCategory.service,
      description: 'Generator wieloletnich wątków fabularnych drużyny gracza',
    ),
    Package4TaskSpec(
      taskNumber: 348,
      filePath: 'lib/ui/widgets/career_storyline_cutscene_card_modal.dart',
      primarySymbols: ['CareerStorylineCutsceneCardModal'],
      category: Package4TaskCategory.uiWidget,
      description: 'Filmowe karty wydarzeń fabularnych z wyborami strategicznymi',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 349,
      filePath:
          'lib/services/career/multi_season_rider_aging_and_decline_curve.dart',
      primarySymbols: ['MultiSeasonRiderAgingAndDeclineCurve'],
      category: Package4TaskCategory.service,
      description: '15-sezonowy model starzenia i ewolucji profilu kolarza',
    ),
    Package4TaskSpec(
      taskNumber: 350,
      filePath: 'lib/ui/widgets/rider_career_trajectory_forecast_chart.dart',
      primarySymbols: ['RiderCareerTrajectoryForecastChart'],
      category: Package4TaskCategory.uiWidget,
      description: 'Wykres 5-letniej prognozy OVR/FTP z przedziałem ufności skauta',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 351,
      filePath: 'lib/engine/peloton/team_leader_change_on_the_road_logic.dart',
      primarySymbols: ['TeamLeaderChangeOnTheRoadLogic'],
      category: Package4TaskCategory.pelotonAi,
      description: 'Dynamiczna zmiana lidera drużyny na szosie po kraksie lub Bad Legs',
    ),
    Package4TaskSpec(
      taskNumber: 352,
      filePath: 'lib/engine/events/daily_rider_day_form_variance_engine.dart',
      primarySymbols: ['DailyRiderDayFormVarianceEngine'],
      category: Package4TaskCategory.pelotonAi,
      description: 'System dyspozycji dnia „The Legs” od -3 do +3 diamentów',
    ),
    Package4TaskSpec(
      taskNumber: 353,
      filePath: 'lib/ui/widgets/daily_legs_diamond_indicator_widget.dart',
      primarySymbols: ['DailyLegsDiamondIndicatorWidget'],
      category: Package4TaskCategory.uiWidget,
      description: 'Wskaźnik diamentów dyspozycji dnia na kartach kolarzy w HUD',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 354,
      filePath: 'lib/ui/screens/race_replay_director_theater_screen.dart',
      primarySymbols: ['RaceReplayDirectorTheaterScreen'],
      category: Package4TaskCategory.uiScreen,
      description: 'Kino Powtórek Wyścigowych z kamerami 176 kolarzy i Aero Vision',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 355,
      filePath: 'test/be_a_pro_career_and_ds_orders_test.dart',
      primarySymbols: ['main'],
      category: Package4TaskCategory.testSuite,
      description: 'Testy jednostkowe i integracyjne trybu Be a Pro i rozkazów DS',
    ),
    Package4TaskSpec(
      taskNumber: 356,
      filePath: 'test/cyclocross_mud_and_bunnyhop_test.dart',
      primarySymbols: ['main'],
      category: Package4TaskCategory.testSuite,
      description: 'Testy fizyki błota, Dismount & Run, Bunny-Hop i wymiany w Pit Lane',
    ),
    Package4TaskSpec(
      taskNumber: 357,
      filePath: 'test/velodrome_hour_record_physics_test.dart',
      primarySymbols: ['main'],
      category: Package4TaskCategory.testSuite,
      description: 'Testy fizyki welodromu 42°, gęstości powietrza i Rekordu Godzinnego',
    ),
    Package4TaskSpec(
      taskNumber: 358,
      filePath: 'test/pedal_biomechanics_and_hydrogel_test.dart',
      primarySymbols: ['main'],
      category: Package4TaskCategory.testSuite,
      description: 'Testy biomechaniki korby L/R oraz suplementacji 110g/h i dwuwęglanu',
    ),
    Package4TaskSpec(
      taskNumber: 359,
      filePath: 'test/first_person_cockpit_and_holo_card_test.dart',
      primarySymbols: ['main'],
      category: Package4TaskCategory.testSuite,
      description: 'Testy widgetów First-Person Cockpit 3D i kart holograficznych',
    ),
    Package4TaskSpec(
      taskNumber: 360,
      filePath: 'lib/core/diagnostics/save_compatibility_v4_migrator.dart',
      primarySymbols: ['SaveCompatibilityV4Migrator'],
      category: Package4TaskCategory.diagnostics,
      description: 'Migrator zapisów gry v4 dla struktur Paczki #4',
      requiresResponsiveLayout: true,
    ),
    Package4TaskSpec(
      taskNumber: 361,
      filePath: 'lib/core/router/app_router.dart',
      primarySymbols: ['AppRoutes'],
      category: Package4TaskCategory.diagnostics,
      description: 'Trasy AppRouter dla Be a Pro, CX, Welodromu, Kina i Albumu Kart',
    ),
    Package4TaskSpec(
      taskNumber: 362,
      filePath: 'lib/core/diagnostics/sniper_package_4_audit_runner.dart',
      primarySymbols: ['SniperPackage4AuditRunner', 'SniperPackage4AuditPanel'],
      category: Package4TaskCategory.diagnostics,
      description: 'Skrypt audytowy weryfikujący integrację Paczki #4, testy i flutter analyze',
      requiresResponsiveLayout: true,
    ),
  ];

  static final RegExp _testPassRegex = RegExp(
    r'\+(\d+)(?:\s+~(\d+))?(?:\s+-(\d+))?:',
  );

  /// Rozwiązuje katalog główny projektu (szukając `pubspec.yaml` i `docs/CODE_MAP.md`).
  String resolveProjectRoot([String? explicitRoot]) {
    if (explicitRoot != null && explicitRoot.trim().isNotEmpty) {
      return explicitRoot.trim();
    }
    var dir = Directory.current;
    for (var i = 0; i < 6; i++) {
      final pubspec = File('${dir.path}${Platform.pathSeparator}pubspec.yaml');
      final codeMap = File(
        '${dir.path}${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md',
      );
      if (pubspec.existsSync() && codeMap.existsSync()) {
        return dir.path;
      }
      if (dir.parent.path == dir.path) break;
      dir = dir.parent;
    }
    return Directory.current.path;
  }

  /// Uruchamia pełny audyt integracji Paczki #4 (#313–#362).
  Future<Package4AuditReport> runFullAudit({
    String? projectRoot,
    bool runFlutterAnalyze = true,
    bool runFlutterTest = true,
    List<String>? testTargets,
    List<Package4TaskSpec>? manifest,
  }) async {
    final stopwatch = Stopwatch()..start();
    final root = resolveProjectRoot(projectRoot);
    final effectiveManifest = manifest ?? package4Manifest;
    final corpus = _loadDartCorpus(root);

    final codeMapFile = File(
      '$root${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md',
    );
    final codeMapContent =
        codeMapFile.existsSync() ? codeMapFile.readAsStringSync() : '';

    final taskResults = <Package4TaskAuditResult>[];
    for (final spec in effectiveManifest) {
      taskResults.add(
        auditSingleTask(
          projectRoot: root,
          spec: spec,
          codeMapContent: codeMapContent,
          corpus: corpus,
        ),
      );
    }

    final codeMapResult = auditCodeMap(
      projectRoot: root,
      codeMapContent: codeMapContent,
      manifest: effectiveManifest,
    );

    final integrationResult = auditGameIntegration(
      projectRoot: root,
      taskResults: taskResults,
      corpus: corpus,
    );

    final analyzeResult = runFlutterAnalyze
        ? await runFlutterAnalyzeProcess(root)
        : Package4FlutterAnalyzeResult.skipped();

    final testResult = runFlutterTest
        ? await runFlutterTestProcess(
            root,
            targetPaths: testTargets ?? package4TestTargets,
          )
        : Package4FlutterTestResult.skipped();

    stopwatch.stop();
    return Package4AuditReport(
      generatedAt: DateTime.now(),
      projectRoot: root,
      taskResults: taskResults,
      codeMapResult: codeMapResult,
      integrationResult: integrationResult,
      analyzeResult: analyzeResult,
      testResult: testResult,
      duration: stopwatch.elapsed,
    );
  }

  /// Audytuje pojedynczy plik z manifestu Paczki #4.
  Package4TaskAuditResult auditSingleTask({
    required String projectRoot,
    required Package4TaskSpec spec,
    required String codeMapContent,
    required Package4DartCorpusIndex corpus,
  }) {
    final normalizedPath =
        spec.filePath.replaceAll('/', Platform.pathSeparator);
    final file = File('$projectRoot${Platform.pathSeparator}$normalizedPath');
    final exists = file.existsSync();
    if (!exists) {
      return Package4TaskAuditResult(
        spec: spec,
        fileExists: false,
        fileSizeBytes: 0,
        lineCount: 0,
        presentSymbols: const [],
        missingSymbols: spec.primarySymbols,
        todoMarkersCount: 0,
        unimplementedThrowsCount: 0,
        inCodeMap: codeMapContent.contains(spec.filePath),
        missingSymbolsInCodeMap: spec.primarySymbols,
        hasResponsiveLayout: false,
        usesAppColors: false,
        brokenRelativeImports: const [],
        libReferencesCount: 0,
        testReferencesCount: 0,
        issues: ['Brak pliku ${spec.filePath}'],
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
      }
    }

    final todoRegex = RegExp(r'\b(TODO|FIXME|XXX)\b');
    var todoCount = 0;
    for (final line in lines) {
      final trimmed = line.trimLeft();
      if ((trimmed.startsWith('//') || trimmed.startsWith('/*') || trimmed.startsWith('*')) &&
          !trimmed.contains('RegExp(') &&
          todoRegex.hasMatch(trimmed)) {
        todoCount++;
      }
    }

    final unimplementedMatches =
        RegExp(r'throw\s+UnimplementedError\s*\(').allMatches(content);
    var unimplementedCount = 0;
    for (final match in unimplementedMatches) {
      final lineIndex =
          content.substring(0, match.start).split('\n').length - 1;
      final lineText = lineIndex < lines.length ? lines[lineIndex] : '';
      if (!lineText.contains('RegExp(')) {
        unimplementedCount++;
      }
    }

    final inCodeMap = codeMapContent.contains(spec.filePath);
    final missingCodeMapSymbols = <String>[];
    if (spec.category != Package4TaskCategory.testSuite) {
      for (final sym in spec.primarySymbols) {
        if (!codeMapContent.contains(sym)) {
          missingCodeMapSymbols.add(sym);
        }
      }
    }

    final hasResponsiveLayout = !spec.requiresResponsiveLayout ||
        content.contains('LayoutBuilder') ||
        content.contains('MediaQuery');
    final usesAppColors = !spec.requiresResponsiveLayout ||
        content.contains('AppColors') ||
        content.contains('AppTheme');

    final brokenImports = _findBrokenRelativeImports(
      content: content,
      fileDir: file.parent,
      projectRoot: projectRoot,
    );

    final refCounts = _countCrossReferences(spec: spec, corpus: corpus);

    final issues = <String>[];
    if (bytes == 0) {
      issues.add('Plik jest pusty');
    }
    if (missingSymbols.isNotEmpty) {
      issues.add('Brakujące deklaracje: ${missingSymbols.join(', ')}');
    }
    if (todoCount > 0) {
      issues.add('Wykryto znaczniki TODO/FIXME ($todoCount)');
    }
    if (unimplementedCount > 0) {
      issues.add('Wykryto UnimplementedError ($unimplementedCount)');
    }
    if (!inCodeMap) {
      issues.add('Brak wpisu w docs/CODE_MAP.md');
    }
    if (brokenImports.isNotEmpty) {
      issues.add('Uszkodzone importy: ${brokenImports.join(', ')}');
    }
    if (spec.requiresResponsiveLayout && !hasResponsiveLayout) {
      issues.add('Brak LayoutBuilder / MediaQuery dla responsywności');
    }

    return Package4TaskAuditResult(
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

  /// Weryfikuje kompletność wpisów dla Paczki #4 w `docs/CODE_MAP.md`.
  Package4CodeMapAuditResult auditCodeMap({
    required String projectRoot,
    String? codeMapContent,
    List<Package4TaskSpec>? manifest,
  }) {
    final effectiveManifest = manifest ?? package4Manifest;
    final codeMapFile = File(
      '$projectRoot${Platform.pathSeparator}docs${Platform.pathSeparator}CODE_MAP.md',
    );
    final exists = codeMapContent != null || codeMapFile.existsSync();
    if (!exists) {
      return Package4CodeMapAuditResult(
        codeMapExists: false,
        totalLines: 0,
        package4CoveredCount: 0,
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
      if (spec.category != Package4TaskCategory.testSuite) {
        final missingSym = spec.primarySymbols
            .where((sym) => !content.contains(sym))
            .toList();
        if (missingSym.isNotEmpty) {
          missingSymbolsByFile[spec.filePath] = missingSym;
        }
      }
    }

    return Package4CodeMapAuditResult(
      codeMapExists: true,
      totalLines: totalLines,
      package4CoveredCount: covered,
      missingFilePaths: missingFilePaths,
      missingSymbolsByFile: missingSymbolsByFile,
    );
  }

  /// Weryfikuje integrację modułów Paczki #4 z resztą gry.
  Package4IntegrationCheckResult auditGameIntegration({
    required String projectRoot,
    required List<Package4TaskAuditResult> taskResults,
    Package4DartCorpusIndex? corpus,
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
      if (result.spec.category != Package4TaskCategory.testSuite &&
          result.spec.taskNumber != 362) {
        integrableCount++;
        if (result.totalReferencesCount > 0) {
          integratedCount++;
        }
      }
    }

    return Package4IntegrationCheckResult(
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
  Future<Package4FlutterAnalyzeResult> runFlutterAnalyzeProcess(
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
          issues.where((i) => i.severity == Package4AuditSeverity.error).length;
      final warnings = issues
          .where((i) => i.severity == Package4AuditSeverity.warning)
          .length;
      final infos =
          issues.where((i) => i.severity == Package4AuditSeverity.info).length;

      return Package4FlutterAnalyzeResult(
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
      return Package4FlutterAnalyzeResult(
        executed: true,
        exitCode: -1,
        errorCount: 1,
        warningCount: 0,
        infoCount: 0,
        issues: [
          Package4AnalyzeIssue(
            severity: Package4AuditSeverity.error,
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

  /// Uruchamia testy jednostkowe i widgetowe `flutter test` i parsuje podsumowanie.
  Future<Package4FlutterTestResult> runFlutterTestProcess(
    String projectRoot, {
    List<String> targetPaths = const [],
  }) async {
    final stopwatch = Stopwatch()..start();
    final executable = Platform.isWindows ? 'flutter.bat' : 'flutter';
    final args = <String>[
      'test',
      '--no-pub',
      '--timeout',
      '30s',
      ...targetPaths,
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
      final parsed = parseFlutterTestOutput(combined);

      return Package4FlutterTestResult(
        executed: true,
        exitCode: result.exitCode,
        totalPassed: parsed.passed,
        totalFailed: parsed.failed,
        totalSkipped: parsed.skipped,
        failedTestNames: parsed.failedNames,
        executedTargets: targetPaths,
        rawOutput: combined,
        duration: stopwatch.elapsed,
      );
    } on ProcessException catch (e) {
      stopwatch.stop();
      return Package4FlutterTestResult(
        executed: true,
        exitCode: -1,
        totalPassed: 0,
        totalFailed: 1,
        totalSkipped: 0,
        failedTestNames: [
          'Nie udało się uruchomić flutter test: ${e.message}',
        ],
        executedTargets: targetPaths,
        rawOutput: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Parsuje standardowe linie wyjścia `flutter analyze`.
  static List<Package4AnalyzeIssue> parseFlutterAnalyzeOutput(String output) {
    final issues = <Package4AnalyzeIssue>[];
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
        'error' => Package4AuditSeverity.error,
        'warning' => Package4AuditSeverity.warning,
        _ => Package4AuditSeverity.info,
      };
      issues.add(
        Package4AnalyzeIssue(
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

  /// Parsuje wyjście komendy `flutter test`.
  static ({int passed, int skipped, int failed, List<String> failedNames})
      parseFlutterTestOutput(String output) {
    var passed = 0;
    var skipped = 0;
    var failed = 0;
    for (final match in _testPassRegex.allMatches(output)) {
      passed = int.tryParse(match.group(1) ?? '0') ?? passed;
      if (match.group(2) != null) {
        skipped = int.tryParse(match.group(2)!) ?? skipped;
      }
      if (match.group(3) != null) {
        failed = int.tryParse(match.group(3)!) ?? failed;
      }
    }

    final failedNames = <String>[];
    for (final line in const LineSplitter().convert(output)) {
      if (line.contains('[E]')) {
        failedNames.add(line.trim());
      }
    }
    return (
      passed: passed,
      skipped: skipped,
      failed: failed,
      failedNames: failedNames,
    );
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
          final rel = uri
              .substring(prefix.length)
              .replaceAll('/', Platform.pathSeparator);
          final target = File(
            '$projectRoot${Platform.pathSeparator}lib${Platform.pathSeparator}$rel',
          );
          if (!target.existsSync()) {
            broken.add(uri);
          }
        }
        continue;
      }
      final resolved = File(
        '${fileDir.path}${Platform.pathSeparator}${uri.replaceAll('/', Platform.pathSeparator)}',
      );
      if (!resolved.existsSync()) {
        broken.add(uri);
      }
    }
    return broken;
  }

  static Package4DartCorpusIndex _loadDartCorpus(String projectRoot) {
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
    return Package4DartCorpusIndex(libFiles: libFiles, testFiles: testFiles);
  }

  static ({int libCount, int testCount}) _countCrossReferences({
    required Package4TaskSpec spec,
    required Package4DartCorpusIndex corpus,
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

class Package4DartCorpusIndex {
  final Map<String, String> libFiles;
  final Map<String, String> testFiles;

  const Package4DartCorpusIndex({
    required this.libFiles,
    required this.testFiles,
  });
}

/// Stan kontrolera audytu Paczki #4 w Riverpod.
@immutable
class SniperPackage4AuditState {
  final bool isRunning;
  final Package4AuditReport? report;
  final String? errorMessage;
  final Package4TaskCategory? selectedCategory;
  final bool onlyFailures;
  final String searchQuery;
  final bool includeFlutterAnalyze;
  final bool includeFlutterTest;

  const SniperPackage4AuditState({
    this.isRunning = false,
    this.report,
    this.errorMessage,
    this.selectedCategory,
    this.onlyFailures = false,
    this.searchQuery = '',
    this.includeFlutterAnalyze = true,
    this.includeFlutterTest = true,
  });

  SniperPackage4AuditState copyWith({
    bool? isRunning,
    Package4AuditReport? report,
    String? errorMessage,
    bool clearError = false,
    Package4TaskCategory? selectedCategory,
    bool clearCategory = false,
    bool? onlyFailures,
    String? searchQuery,
    bool? includeFlutterAnalyze,
    bool? includeFlutterTest,
  }) {
    return SniperPackage4AuditState(
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedCategory:
          clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      onlyFailures: onlyFailures ?? this.onlyFailures,
      searchQuery: searchQuery ?? this.searchQuery,
      includeFlutterAnalyze:
          includeFlutterAnalyze ?? this.includeFlutterAnalyze,
      includeFlutterTest: includeFlutterTest ?? this.includeFlutterTest,
    );
  }

  List<Package4TaskAuditResult> get filteredResults {
    final results = report?.taskResults ?? const <Package4TaskAuditResult>[];
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

/// Notifier zarządzający wykonywaniem i filtrowaniem audytu Paczki #4.
class SniperPackage4AuditNotifier
    extends StateNotifier<SniperPackage4AuditState> {
  final SniperPackage4AuditRunner _runner;
  final String? _projectRoot;

  SniperPackage4AuditNotifier({
    SniperPackage4AuditRunner runner = const SniperPackage4AuditRunner(),
    String? projectRoot,
  })  : _runner = runner,
        _projectRoot = projectRoot,
        super(const SniperPackage4AuditState());

  Future<void> runAudit({
    bool? includeFlutterAnalyze,
    bool? includeFlutterTest,
  }) async {
    if (state.isRunning) return;
    final runAnalyze = includeFlutterAnalyze ?? state.includeFlutterAnalyze;
    final runTests = includeFlutterTest ?? state.includeFlutterTest;
    state = state.copyWith(isRunning: true, clearError: true);
    try {
      final report = await _runner.runFullAudit(
        projectRoot: _projectRoot,
        runFlutterAnalyze: runAnalyze,
        runFlutterTest: runTests,
      );
      if (!mounted) return;
      state = state.copyWith(isRunning: false, report: report);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isRunning: false,
        errorMessage: 'Błąd audytu Paczki #4: $e',
      );
    }
  }

  void toggleIncludeAnalyze(bool value) {
    state = state.copyWith(includeFlutterAnalyze: value);
  }

  void toggleIncludeTests(bool value) {
    state = state.copyWith(includeFlutterTest: value);
  }

  void setCategoryFilter(Package4TaskCategory? category) {
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

/// Globalny provider audytu Paczki #4 (#313–#362).
final sniperPackage4AuditProvider = StateNotifierProvider.autoDispose<
    SniperPackage4AuditNotifier, SniperPackage4AuditState>(
  (ref) => SniperPackage4AuditNotifier(),
);

/// Responsywny panel UI prezentujący wyniki audytu integracji Paczki #4 (#313–#362).
class SniperPackage4AuditPanel extends ConsumerStatefulWidget {
  final bool autoRunOnInit;

  const SniperPackage4AuditPanel({
    super.key,
    this.autoRunOnInit = false,
  });

  @override
  ConsumerState<SniperPackage4AuditPanel> createState() =>
      _SniperPackage4AuditPanelState();
}

class _SniperPackage4AuditPanelState
    extends ConsumerState<SniperPackage4AuditPanel> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searchFocused = false;
  int? _expandedTaskNumber;
  String? _statusToast;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleSearchFocusChange);
    if (widget.autoRunOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(sniperPackage4AuditProvider.notifier).runAudit(
              includeFlutterAnalyze: false,
              includeFlutterTest: false,
            );
      });
    }
  }

  void _handleSearchFocusChange() {
    if (mounted) {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _searchFocusNode.removeListener(_handleSearchFocusChange);
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _copySummary(Package4AuditReport report) {
    Clipboard.setData(ClipboardData(text: report.toMarkdownSummary()));
    setState(() => _statusToast = 'Skopiowano raport Markdown do schowka');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sniperPackage4AuditProvider);
    final notifier = ref.read(sniperPackage4AuditProvider.notifier);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < 640;
        final isWide = width >= 1200;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          padding: EdgeInsets.all(isCompact ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, state, notifier, isCompact),
              const SizedBox(height: 16),
              _buildGateToggles(state, notifier),
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                _buildErrorBanner(state.errorMessage!),
              ],
              if (_statusToast != null) ...[
                const SizedBox(height: 12),
                _buildInfoToast(_statusToast!),
              ],
              const SizedBox(height: 16),
              if (state.report != null) ...[
                _buildSummaryMetrics(state.report!, isCompact, isWide),
                const SizedBox(height: 16),
                _buildFilterBar(state, notifier, isCompact),
                const SizedBox(height: 16),
                _buildResultsList(state.filteredResults, isCompact),
              ] else
                _buildEmptyState(state.isRunning),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    SniperPackage4AuditState state,
    SniperPackage4AuditNotifier notifier,
    bool isCompact,
  ) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.goldAccent.withValues(alpha: 0.45),
                ),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: AppColors.goldAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'Audyt Integracji Paczki #4 (#313–#362)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Weryfikacja 50 modułów Be a Pro, CX, Welodromu, Biomechaniki, CODE_MAP.md, testów oraz flutter analyze.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final actionsBlock = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _AuditActionButton(
          label: state.isRunning ? 'Skanowanie...' : 'Uruchom Audyt',
          icon: state.isRunning
              ? Icons.hourglass_top_rounded
              : Icons.play_arrow_rounded,
          isPrimary: true,
          enabled: !state.isRunning,
          onPressed: () => notifier.runAudit(
            includeFlutterAnalyze: state.includeFlutterAnalyze,
            includeFlutterTest: state.includeFlutterTest,
          ),
        ),
        _AuditActionButton(
          label: 'Kopiuj Raport',
          icon: Icons.content_copy_rounded,
          isPrimary: false,
          enabled: state.report != null && !state.isRunning,
          onPressed: state.report != null
              ? () => _copySummary(state.report!)
              : null,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 14),
          actionsBlock,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        actionsBlock,
      ],
    );
  }

  Widget _buildGateToggles(
    SniperPackage4AuditState state,
    SniperPackage4AuditNotifier notifier,
  ) {
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _AuditFilterChip(
          label: 'Uruchom flutter analyze',
          icon: Icons.rule_rounded,
          selected: state.includeFlutterAnalyze,
          enabled: !state.isRunning,
          onTap: () =>
              notifier.toggleIncludeAnalyze(!state.includeFlutterAnalyze),
        ),
        _AuditFilterChip(
          label: 'Uruchom flutter test',
          icon: Icons.science_rounded,
          selected: state.includeFlutterTest,
          enabled: !state.isRunning,
          onTap: () => notifier.toggleIncludeTests(!state.includeFlutterTest),
        ),
      ],
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.crimsonAlert,
            size: 18,
          ),
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

  Widget _buildInfoToast(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.statusSuccess.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.statusSuccess.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.statusSuccess,
            size: 18,
          ),
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

  Widget _buildSummaryMetrics(
    Package4AuditReport report,
    bool isCompact,
    bool isWide,
  ) {
    final cards = [
      _MetricCard(
        title: 'Zadania #313–#362',
        value: '${report.passedTasks}/${report.totalTasks}',
        subtitle: report.failedTasks == 0
            ? 'Wszystkie spójne'
            : '${report.failedTasks} wymaga uwagi',
        accentColor: report.failedTasks == 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.task_alt_rounded,
      ),
      _MetricCard(
        title: 'CODE_MAP.md',
        value: '${report.codeMapResult.package4CoveredCount}/50',
        subtitle: report.codeMapResult.passed
            ? 'Pełne pokrycie'
            : 'Brak ${report.codeMapResult.missingFilePaths.length} wpisów',
        accentColor: report.codeMapResult.passed
            ? AppColors.statusSuccess
            : AppColors.amberWarning,
        icon: Icons.map_rounded,
      ),
      _MetricCard(
        title: 'Mosty Integracji',
        value:
            '${report.integrationResult.verifiedCoreBridges.length}/${SniperPackage4AuditRunner.coreIntegrationBridges.length}',
        subtitle:
            '${report.integrationResult.integratedTasksCount}/${report.integrationResult.totalIntegrableTasksCount} z referencjami',
        accentColor: report.integrationResult.passed
            ? AppColors.accentBlue
            : AppColors.crimsonAlert,
        icon: Icons.hub_rounded,
      ),
      _MetricCard(
        title: 'Analyze & Testy',
        value: report.analyzeResult.executed
            ? '${report.analyzeResult.errorCount} err'
            : 'Pominięto',
        subtitle: report.testResult.executed
            ? 'Testy: ${report.testResult.totalPassed} OK / ${report.testResult.totalFailed} ERR'
            : 'Testy pominięte',
        accentColor: (report.analyzeResult.passed && report.testResult.passed)
            ? AppColors.goldAccent
            : AppColors.amberWarning,
        icon: Icons.verified_rounded,
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

    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

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

  Widget _buildFilterBar(
    SniperPackage4AuditState state,
    SniperPackage4AuditNotifier notifier,
    bool isCompact,
  ) {
    final searchField = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _searchFocused ? AppColors.goldAccent : AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: notifier.setSearchQuery,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Szukaj po #numerze, ścieżce lub klasie...',
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
          suffixIcon: state.searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    notifier.setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );

    final chips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AuditFilterChip(
          label: 'Tylko błędy',
          icon: Icons.warning_amber_rounded,
          selected: state.onlyFailures,
          enabled: true,
          onTap: () => notifier.setOnlyFailures(!state.onlyFailures),
        ),
        for (final category in Package4TaskCategory.values)
          _AuditFilterChip(
            label: category.label,
            icon: category.icon,
            selected: state.selectedCategory == category,
            enabled: true,
            onTap: () => notifier.setCategoryFilter(category),
          ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          chips,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        searchField,
        const SizedBox(height: 12),
        chips,
      ],
    );
  }

  Widget _buildResultsList(
    List<Package4TaskAuditResult> items,
    bool isCompact,
  ) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: const Center(
          child: Text(
            'Brak wyników spełniających wybrane filtry.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final isExpanded = _expandedTaskNumber == item.spec.taskNumber;
        return _TaskAuditRow(
          item: item,
          isExpanded: isExpanded,
          isCompact: isCompact,
          onToggle: () {
            setState(() {
              _expandedTaskNumber =
                  isExpanded ? null : item.spec.taskNumber;
            });
          },
        );
      },
    );
  }

  Widget _buildEmptyState(bool isRunning) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            isRunning ? Icons.radar_rounded : Icons.fact_check_outlined,
            size: 36,
            color: AppColors.goldAccent,
          ),
          const SizedBox(height: 12),
          Text(
            isRunning
                ? 'Trwa weryfikacja integracji Paczki #4, testów i analizatora...'
                : 'Kliknij „Uruchom Audyt”, aby zweryfikować zadania #313–#362, testy i flutter analyze.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuditActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback? onPressed;

  const _AuditActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_AuditActionButton> createState() => _AuditActionButtonState();
}

class _AuditActionButtonState extends State<_AuditActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgBase =
        widget.isPrimary ? AppColors.primaryAccent : AppColors.surfaceLight;
    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _pressed
            ? bgBase.withValues(alpha: 0.85)
            : _hovered
                ? bgBase.withValues(alpha: 0.92)
                : bgBase;

    final borderColor = !widget.enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _focused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.5)
                : AppTheme.borderColor;

    final textColor = widget.enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.5);

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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 17, color: textColor),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AuditFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  State<_AuditFilterChip> createState() => _AuditFilterChipState();
}

class _AuditFilterChipState extends State<_AuditFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.selected
        ? AppColors.goldAccent.withValues(alpha: 0.16)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.background;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.goldAccent
            : AppTheme.borderColor;
    final contentColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.selected
            ? AppColors.goldAccent
            : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: contentColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w500,
                    color: contentColor,
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

class _TaskAuditRow extends StatefulWidget {
  final Package4TaskAuditResult item;
  final bool isExpanded;
  final bool isCompact;
  final VoidCallback onToggle;

  const _TaskAuditRow({
    required this.item,
    required this.isExpanded,
    required this.isCompact,
    required this.onToggle,
  });

  @override
  State<_TaskAuditRow> createState() => _TaskAuditRowState();
}

class _TaskAuditRowState extends State<_TaskAuditRow> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final severity = widget.item.severity;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.9)
                : AppColors.surfaceLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focused ? AppColors.goldAccent : AppTheme.borderColor,
              width: 1.0,
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
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: severity.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '#${widget.item.spec.taskNumber}',
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
                    child: Text(
                      widget.item.spec.filePath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    widget.isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (widget.isExpanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.item.spec.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    _DetailPill(
                      label: 'Linie: ${widget.item.lineCount}',
                    ),
                    _DetailPill(
                      label:
                          'Ref lib/test: ${widget.item.libReferencesCount}/${widget.item.testReferencesCount}',
                    ),
                    _DetailPill(
                      label: widget.item.inCodeMap
                          ? 'CODE_MAP: OK'
                          : 'CODE_MAP: BRAK',
                    ),
                  ],
                ),
                if (widget.item.issues.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Problemy: ${widget.item.issues.join(' | ')}',
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
}

class _DetailPill extends StatelessWidget {
  final String label;

  const _DetailPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
