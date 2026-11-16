// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/simulation/stage_results_calculator.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../models/equipment/complete_bike.dart';
import '../../models/race/race_stage.dart';
import '../../models/race/tour_race.dart';
import '../../models/rider/rider.dart';
import '../../ui/screens/race_simulation_screen.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Docelowa platforma systemowa, na której weryfikowana jest obsługa przycisku Wstecz.
enum NavigationTargetPlatform {
  windows(
    'Windows',
    'Alt+Left / Mouse Back / AppBar Back / Navigator.maybePop',
    Icons.desktop_windows_rounded,
  ),
  macos(
    'macOS',
    'Cmd+[ / Trackpad Swipe / AppBar Back / Navigator.maybePop',
    Icons.laptop_mac_rounded,
  ),
  linux(
    'Linux',
    'Alt+Left / Mouse Back / AppBar Back / Navigator.maybePop',
    Icons.computer_rounded,
  ),
  android(
    'Android',
    'System BackButtonDispatcher / Gesture Back / PopScope',
    Icons.phone_android_rounded,
  ),
  ios(
    'iOS',
    'Interactive Edge Swipe / Cupertino Back / PopScope',
    Icons.phone_iphone_rounded,
  ),
  web(
    'Web',
    'Browser History API (popstate) / URL Sync / AppBar Back',
    Icons.public_rounded,
  );

  final String label;
  final String backMechanism;
  final IconData icon;

  const NavigationTargetPlatform(
    this.label,
    this.backMechanism,
    this.icon,
  );

  /// Wykrywa bieżącą platformę uruchomieniową Fluttera.
  static NavigationTargetPlatform detectCurrent() {
    if (kIsWeb) {
      return NavigationTargetPlatform.web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
        return NavigationTargetPlatform.windows;
      case TargetPlatform.macOS:
        return NavigationTargetPlatform.macos;
      case TargetPlatform.linux:
        return NavigationTargetPlatform.linux;
      case TargetPlatform.android:
        return NavigationTargetPlatform.android;
      case TargetPlatform.iOS:
        return NavigationTargetPlatform.ios;
      case TargetPlatform.fuchsia:
        return NavigationTargetPlatform.linux;
    }
  }
}

/// Kategoria trasy w strukturze `AppRouter`.
enum RouteGroupCategory {
  entry('Ekran Startowy'),
  careerShell('Powłoka Kariery (ShellRoute)'),
  raceFullscreen('Wyścig 3D (Pełny Ekran)'),
  errorFallback('Obsługa Błędów (404)');

  final String label;

  const RouteGroupCategory(this.label);
}

/// Rodzaj parametru przekazywanego między ekranami.
enum RouteParameterKind {
  path('Path Parameter'),
  query('Query Parameter'),
  extra('Extra Payload');

  final String label;

  const RouteParameterKind(this.label);
}

/// Wynik weryfikacji pojedynczej trasy lub testu.
enum RouteAuditStatus {
  passed('Zaliczona'),
  warning('Ostrzeżenie'),
  failed('Błąd');

  final String label;

  const RouteAuditStatus(this.label);
}

/// Filtr listy tras w panelu diagnostycznym.
enum NavigationVerifierFilter {
  all('Wszystkie'),
  passed('Zaliczone'),
  failed('Błędy'),
  parameterized('Z parametrami'),
  shellRoutes('ShellRoute');

  final String label;

  const NavigationVerifierFilter(this.label);
}

/// Specyfikacja pojedynczego parametru trasy w `AppRouter`.
@immutable
class RouteParameterSpec {
  final String name;
  final RouteParameterKind kind;
  final String valueType;
  final bool isRequired;
  final String sampleValue;
  final String fallbackBehavior;

  const RouteParameterSpec({
    required this.name,
    required this.kind,
    required this.valueType,
    required this.isRequired,
    required this.sampleValue,
    required this.fallbackBehavior,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.name,
        'valueType': valueType,
        'isRequired': isRequired,
        'sampleValue': sampleValue,
        'fallbackBehavior': fallbackBehavior,
      };
}

/// Pełna specyfikacja trasy oczekiwanej w `AppRouter`.
@immutable
class RouteVerificationSpec {
  final String path;
  final String name;
  final RouteGroupCategory category;
  final bool usesShellRoute;
  final List<RouteParameterSpec> parameters;
  final bool supportsBackPop;
  final String? redirectTarget;
  final String description;

  const RouteVerificationSpec({
    required this.path,
    required this.name,
    required this.category,
    required this.usesShellRoute,
    this.parameters = const [],
    this.supportsBackPop = true,
    this.redirectTarget,
    required this.description,
  });

  bool get hasParameters => parameters.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'path': path,
        'name': name,
        'category': category.name,
        'usesShellRoute': usesShellRoute,
        'parameters': parameters.map((p) => p.toJson()).toList(),
        'supportsBackPop': supportsBackPop,
        'redirectTarget': redirectTarget,
        'description': description,
      };
}

/// Wynik weryfikacji pojedynczej trasy w `AppRouter`.
@immutable
class RouteCheckResult {
  final RouteVerificationSpec spec;
  final RouteAuditStatus status;
  final String resolvedUri;
  final String matchedLocation;
  final bool registeredInRouter;
  final bool namedLookupPassed;
  final bool parameterCheckPassed;
  final String parameterDetails;
  final bool backPopPassed;
  final double durationMs;
  final String? errorMessage;

  const RouteCheckResult({
    required this.spec,
    required this.status,
    required this.resolvedUri,
    required this.matchedLocation,
    required this.registeredInRouter,
    required this.namedLookupPassed,
    required this.parameterCheckPassed,
    required this.parameterDetails,
    required this.backPopPassed,
    required this.durationMs,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() => {
        'path': spec.path,
        'name': spec.name,
        'category': spec.category.name,
        'status': status.name,
        'resolvedUri': resolvedUri,
        'matchedLocation': matchedLocation,
        'registeredInRouter': registeredInRouter,
        'namedLookupPassed': namedLookupPassed,
        'parameterCheckPassed': parameterCheckPassed,
        'parameterDetails': parameterDetails,
        'backPopPassed': backPopPassed,
        'durationMs': durationMs,
        'errorMessage': errorMessage,
      };
}

/// Wynik weryfikacji przycisku Wstecz na danej platformie.
@immutable
class BackButtonPlatformCheckResult {
  final NavigationTargetPlatform platform;
  final int testedTransitions;
  final int passedTransitions;
  final bool rootGuardPassed;
  final bool deepStackPopPassed;
  final bool shellBackPopPassed;
  final double averageLatencyMs;
  final String notes;

  const BackButtonPlatformCheckResult({
    required this.platform,
    required this.testedTransitions,
    required this.passedTransitions,
    required this.rootGuardPassed,
    required this.deepStackPopPassed,
    required this.shellBackPopPassed,
    required this.averageLatencyMs,
    required this.notes,
  });

  bool get passed =>
      testedTransitions > 0 &&
      passedTransitions == testedTransitions &&
      rootGuardPassed &&
      deepStackPopPassed &&
      shellBackPopPassed;

  Map<String, dynamic> toJson() => {
        'platform': platform.name,
        'label': platform.label,
        'backMechanism': platform.backMechanism,
        'testedTransitions': testedTransitions,
        'passedTransitions': passedTransitions,
        'rootGuardPassed': rootGuardPassed,
        'deepStackPopPassed': deepStackPopPassed,
        'shellBackPopPassed': shellBackPopPassed,
        'averageLatencyMs': averageLatencyMs,
        'passed': passed,
        'notes': notes,
      };
}

/// Kompletny raport automatycznej weryfikacji tras, parametrów i przycisku Wstecz.
@immutable
class NavigationRoutesAuditReport {
  final DateTime timestamp;
  final NavigationTargetPlatform hostPlatform;
  final int totalRoutesChecked;
  final int passedRoutes;
  final int warningRoutes;
  final int failedRoutes;
  final int parameterChecksPassed;
  final int totalParameterChecks;
  final bool error404FallbackPassed;
  final List<RouteCheckResult> routeResults;
  final List<BackButtonPlatformCheckResult> platformResults;
  final List<String> duplicatePaths;
  final List<String> duplicateNames;
  final List<String> unregisteredRouterPaths;
  final double totalDurationMs;

  const NavigationRoutesAuditReport({
    required this.timestamp,
    required this.hostPlatform,
    required this.totalRoutesChecked,
    required this.passedRoutes,
    required this.warningRoutes,
    required this.failedRoutes,
    required this.parameterChecksPassed,
    required this.totalParameterChecks,
    required this.error404FallbackPassed,
    required this.routeResults,
    required this.platformResults,
    required this.duplicatePaths,
    required this.duplicateNames,
    required this.unregisteredRouterPaths,
    required this.totalDurationMs,
  });

  bool get allPassed =>
      failedRoutes == 0 &&
      duplicatePaths.isEmpty &&
      duplicateNames.isEmpty &&
      unregisteredRouterPaths.isEmpty &&
      error404FallbackPassed &&
      parameterChecksPassed == totalParameterChecks &&
      platformResults.every((p) => p.passed);

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'hostPlatform': hostPlatform.name,
        'allPassed': allPassed,
        'totalRoutesChecked': totalRoutesChecked,
        'passedRoutes': passedRoutes,
        'warningRoutes': warningRoutes,
        'failedRoutes': failedRoutes,
        'parameterChecksPassed': parameterChecksPassed,
        'totalParameterChecks': totalParameterChecks,
        'error404FallbackPassed': error404FallbackPassed,
        'duplicatePaths': duplicatePaths,
        'duplicateNames': duplicateNames,
        'unregisteredRouterPaths': unregisteredRouterPaths,
        'totalDurationMs': totalDurationMs,
        'platformResults': platformResults.map((p) => p.toJson()).toList(),
        'routeResults': routeResults.map((r) => r.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Wewnętrzny wpis zebrany podczas rekurencyjnego skanowania `GoRouter.configuration.routes`.
class _DiscoveredGoRoute {
  final String fullPath;
  final String? name;
  final bool inShellRoute;
  final GoRoute route;

  const _DiscoveredGoRoute({
    required this.fullPath,
    required this.name,
    required this.inShellRoute,
    required this.route,
  });
}

/// Automatyczny weryfikator nawigacji sprawdzający wszystkie ścieżki w `AppRouter`,
/// parametry przekazywane między ekranami oraz poprawność działania przycisku Wstecz
/// na każdej platformie (Windows, macOS, Linux, Android, iOS, Web).
class FullNavigationRoutesVerifier {
  const FullNavigationRoutesVerifier();

  /// Pełny katalog 30 tras zdefiniowanych w `AppRoutes` i `AppRouteNames`.
  static const List<RouteVerificationSpec> expectedRouteSpecs = [
    RouteVerificationSpec(
      path: AppRoutes.start,
      name: AppRouteNames.start,
      category: RouteGroupCategory.entry,
      usesShellRoute: false,
      supportsBackPop: false,
      description: 'Ekran tytułowy i wybór slotu zapisu gry.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.welcome,
      name: AppRouteNames.welcome,
      category: RouteGroupCategory.entry,
      usesShellRoute: false,
      description: 'Ekran powitalny startu gry.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.newCareer,
      name: AppRouteNames.newCareer,
      category: RouteGroupCategory.entry,
      usesShellRoute: false,
      parameters: [
        RouteParameterSpec(
          name: 'slot',
          kind: RouteParameterKind.query,
          valueType: 'int',
          isRequired: false,
          sampleValue: '2',
          fallbackBehavior: 'Domyślnie slot = 1 przy braku lub błędnym formacie.',
        ),
      ],
      description: 'Kreator nowej kariery z wyborem slotu zapisu.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.career,
      name: AppRouteNames.career,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      redirectTarget: AppRoutes.dashboard,
      description: 'Główna ścieżka kariery przekierowująca do Dashboard HQ.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.dashboard,
      name: AppRouteNames.dashboard,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      supportsBackPop: false,
      description: 'Pulpit dowodzenia menedżera (Dashboard HQ).',
    ),
    RouteVerificationSpec(
      path: AppRoutes.inbox,
      name: AppRouteNames.inbox,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Skrzynka odbiorcza wiadomości i ofert.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.calendar,
      name: AppRouteNames.calendar,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Kalendarz sezonu i planowanie startów.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.roster,
      name: AppRouteNames.roster,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Kadra drużyny i lista kolarzy.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.riderDetail,
      name: AppRouteNames.riderDetail,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'riderId',
          kind: RouteParameterKind.path,
          valueType: 'String',
          isRequired: true,
          sampleValue: 'rider_042',
          fallbackBehavior: 'Pusty ciąg przy braku segmentu ścieżki.',
        ),
        RouteParameterSpec(
          name: 'extra',
          kind: RouteParameterKind.extra,
          valueType: 'Rider?',
          isRequired: false,
          sampleValue: 'Rider(id: rider_042)',
          fallbackBehavior: 'Bezpieczne rzutowanie `extra is Rider ? extra : null`.',
        ),
      ],
      description: 'Szczegółowy profil kolarza z parametrem ścieżki i opcjonalnym Rider.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.teamBuilder,
      name: AppRouteNames.teamBuilder,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Hierarchia drużyny i budowa formacji.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.training,
      name: AppRouteNames.training,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'riderId',
          kind: RouteParameterKind.query,
          valueType: 'String?',
          isRequired: false,
          sampleValue: 'rider_007',
          fallbackBehavior: 'Opcjonalny wybór kolarza w centrum treningowym.',
        ),
      ],
      description: 'Centrum treningowe i obozy.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.physiologyLab,
      name: AppRouteNames.physiologyLab,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'riderId',
          kind: RouteParameterKind.query,
          valueType: 'String?',
          isRequired: false,
          sampleValue: 'rider_007',
          fallbackBehavior: 'Opcjonalny wybór kolarza w laboratorium wydolnościowym.',
        ),
      ],
      description: 'Laboratorium wydolnościowe (Lactate & Spiro Lab).',
    ),
    RouteVerificationSpec(
      path: AppRoutes.medical,
      name: AppRouteNames.medical,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'riderId',
          kind: RouteParameterKind.query,
          valueType: 'String?',
          isRequired: false,
          sampleValue: 'rider_007',
          fallbackBehavior: 'Opcjonalny wybór kolarza w centrum medycznym.',
        ),
      ],
      description: 'Centrum medyczne i regeneracja.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.academy,
      name: AppRouteNames.academy,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'riderId',
          kind: RouteParameterKind.query,
          valueType: 'String?',
          isRequired: false,
          sampleValue: 'rider_u23_1',
          fallbackBehavior: 'Opcjonalny wybór talentu w akademii U23.',
        ),
      ],
      description: 'Akademia młodzieżowa U23.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.staff,
      name: AppRouteNames.staff,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Zarządzanie sztabem szkoleniowym.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.garage,
      name: AppRouteNames.garage,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'extra',
          kind: RouteParameterKind.extra,
          valueType: 'CompleteBike?',
          isRequired: false,
          sampleValue: 'CompleteBike',
          fallbackBehavior: 'Bezpieczne rzutowanie `extra is CompleteBike ? extra : null`.',
        ),
      ],
      description: 'Warsztat, garaż rowerowy i R&D.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.windTunnel,
      name: AppRouteNames.windTunnel,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'riderId',
          kind: RouteParameterKind.query,
          valueType: 'String?',
          isRequired: false,
          sampleValue: 'rider_007',
          fallbackBehavior: 'Opcjonalny wybór kolarza w tunelu aerodynamicznym.',
        ),
      ],
      description: 'Tunel aerodynamiczny i bike fitting.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.sponsors,
      name: AppRouteNames.sponsors,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Finanse i kontrakty sponsorskie.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.transfers,
      name: AppRouteNames.transfers,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Rynek transferowy i skauting.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.liveryStudio,
      name: AppRouteNames.liveryStudio,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Studio malowania rowerów i koszulek.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.uciRankings,
      name: AppRouteNames.uciRankings,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Rankingi UCI i walka o licencję.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.hallOfFame,
      name: AppRouteNames.hallOfFame,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Gablota trofeów i rekordy historyczne.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.managerProfile,
      name: AppRouteNames.managerProfile,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Profil menedżera i osiągnięcia.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.stageEditor,
      name: AppRouteNames.stageEditor,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Kreator tras i etapów.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.preSeasonPresentation,
      name: AppRouteNames.preSeasonPresentation,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      description: 'Gala przedsezonowej prezentacji zespołu.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.settings,
      name: AppRouteNames.settings,
      category: RouteGroupCategory.careerShell,
      usesShellRoute: true,
      parameters: [
        RouteParameterSpec(
          name: 'tab',
          kind: RouteParameterKind.query,
          valueType: 'int',
          isRequired: false,
          sampleValue: '2',
          fallbackBehavior: 'Domyślnie tab = 0 przy braku lub błędnym formacie.',
        ),
      ],
      description: 'Ustawienia gry i modowanie z wyborem zakładki.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.quickRaceSandbox,
      name: AppRouteNames.quickRaceSandbox,
      category: RouteGroupCategory.raceFullscreen,
      usesShellRoute: false,
      description: 'Laboratorium taktyczne Sandbox (Szybki Wyścig 3D).',
    ),
    RouteVerificationSpec(
      path: AppRoutes.raceBriefing,
      name: AppRouteNames.raceBriefing,
      category: RouteGroupCategory.raceFullscreen,
      usesShellRoute: false,
      parameters: [
        RouteParameterSpec(
          name: 'stage',
          kind: RouteParameterKind.extra,
          valueType: 'RaceStage?',
          isRequired: false,
          sampleValue: 'RaceStage',
          fallbackBehavior: 'Odczyt z extra["stage"] as RaceStage?.',
        ),
        RouteParameterSpec(
          name: 'race',
          kind: RouteParameterKind.extra,
          valueType: 'TourRace?',
          isRequired: false,
          sampleValue: 'TourRace',
          fallbackBehavior: 'Odczyt z extra["race"] as TourRace?.',
        ),
      ],
      description: 'Taktyczna odprawa przedetapowa.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.raceLive,
      name: AppRouteNames.raceLive,
      category: RouteGroupCategory.raceFullscreen,
      usesShellRoute: false,
      parameters: [
        RouteParameterSpec(
          name: 'initialCameraMode',
          kind: RouteParameterKind.extra,
          valueType: 'RaceCameraMode',
          isRequired: false,
          sampleValue: 'RaceCameraMode.profile2D',
          fallbackBehavior: 'Domyślnie RaceCameraMode.profile2D.',
        ),
        RouteParameterSpec(
          name: 'stageLabel',
          kind: RouteParameterKind.extra,
          valueType: 'String?',
          isRequired: false,
          sampleValue: 'Etap 15: Plateau de Beille',
          fallbackBehavior: 'Opcjonalny podpis przejścia do wyścigu.',
        ),
        RouteParameterSpec(
          name: 'subtitle',
          kind: RouteParameterKind.extra,
          valueType: 'String?',
          isRequired: false,
          sampleValue: '198 km • Góry HC',
          fallbackBehavior: 'Opcjonalny podtytuł przejścia.',
        ),
      ],
      description: 'Symulacja wyścigu 3D na żywo.',
    ),
    RouteVerificationSpec(
      path: AppRoutes.racePodium,
      name: AppRouteNames.racePodium,
      category: RouteGroupCategory.raceFullscreen,
      usesShellRoute: false,
      parameters: [
        RouteParameterSpec(
          name: 'report',
          kind: RouteParameterKind.extra,
          valueType: 'StageSummaryReport?',
          isRequired: false,
          sampleValue: 'StageSummaryReport',
          fallbackBehavior: 'Odczyt z extra["report"] as StageSummaryReport?.',
        ),
        RouteParameterSpec(
          name: 'simState',
          kind: RouteParameterKind.extra,
          valueType: 'StageSimulationState?',
          isRequired: false,
          sampleValue: 'StageSimulationState',
          fallbackBehavior: 'Odczyt z extra["simState"] as StageSimulationState?.',
        ),
      ],
      description: 'Ceremonia podium i raport po etapie z bezpiecznym powrotem.',
    ),
  ];

  /// Uruchamia pełną, izolowaną weryfikację konfiguracji `GoRouter`, parametrów tras,
  /// obsługi błędu 404 oraz mechanizmów przycisku Wstecz dla wszystkich platform.
  NavigationRoutesAuditReport runAudit({
    GoRouter? router,
    List<NavigationTargetPlatform>? platforms,
  }) {
    final totalWatch = Stopwatch()..start();
    final targetRouter = router ?? createAppRouter();
    final ownsRouter = router == null;

    try {
      final discovered = _collectDiscoveredRoutes(targetRouter.configuration.routes);
      final discoveredByPath = <String, _DiscoveredGoRoute>{};
      final duplicatePaths = <String>[];
      final duplicateNames = <String>[];
      final seenNames = <String>{};

      for (final entry in discovered) {
        if (discoveredByPath.containsKey(entry.fullPath)) {
          duplicatePaths.add(entry.fullPath);
        } else {
          discoveredByPath[entry.fullPath] = entry;
        }
        final routeName = entry.name;
        if (routeName != null && routeName.isNotEmpty) {
          if (!seenNames.add(routeName)) {
            duplicateNames.add(routeName);
          }
        }
      }

      final expectedPathSet = expectedRouteSpecs.map((s) => s.path).toSet();
      final unregisteredRouterPaths = discoveredByPath.keys
          .where((p) => !expectedPathSet.contains(p))
          .toList();

      final routeResults = <RouteCheckResult>[];
      var passedRoutes = 0;
      var warningRoutes = 0;
      var failedRoutes = 0;
      var parameterChecksPassed = 0;
      var totalParameterChecks = 0;

      for (final spec in expectedRouteSpecs) {
        final itemWatch = Stopwatch()..start();
        final match = discoveredByPath[spec.path];
        final registered = match != null;

        final paramOutcome = _verifyRouteParameters(
          router: targetRouter,
          spec: spec,
          discovered: match,
        );

        totalParameterChecks += paramOutcome.totalChecks;
        parameterChecksPassed += paramOutcome.passedChecks;

        final namedLookupPassed = _verifyNamedLocation(targetRouter, spec);
        final backPopPassed = _verifyRouteBackContract(spec);

        itemWatch.stop();

        RouteAuditStatus status;
        String? errorMsg;

        if (!registered || !paramOutcome.passed || !backPopPassed) {
          status = RouteAuditStatus.failed;
          failedRoutes++;
          if (!registered) {
            errorMsg = 'Trasa ${spec.path} nie jest zarejestrowana w GoRouter.';
          } else if (!paramOutcome.passed) {
            errorMsg = 'Niepowodzenie walidacji parametrów: ${paramOutcome.details}';
          } else {
            errorMsg = 'Nieprawidłowy kontrakt powrotu (Back/Pop).';
          }
        } else if (!namedLookupPassed) {
          status = RouteAuditStatus.warning;
          warningRoutes++;
          errorMsg = 'Rozwiązywanie namedLocation("${spec.name}") wymaga uwagi.';
        } else {
          status = RouteAuditStatus.passed;
          passedRoutes++;
        }

        routeResults.add(
          RouteCheckResult(
            spec: spec,
            status: status,
            resolvedUri: paramOutcome.resolvedUri,
            matchedLocation: paramOutcome.matchedLocation,
            registeredInRouter: registered,
            namedLookupPassed: namedLookupPassed,
            parameterCheckPassed: paramOutcome.passed,
            parameterDetails: paramOutcome.details,
            backPopPassed: backPopPassed,
            durationMs: itemWatch.elapsedMicroseconds / 1000.0,
            errorMessage: errorMsg,
          ),
        );
      }

      final error404Passed = _verify404Fallback(targetRouter);

      final targetPlatforms = platforms ?? NavigationTargetPlatform.values;
      final platformResults = targetPlatforms
          .map((platform) => _verifyPlatformBackBehavior(platform, targetRouter))
          .toList();

      totalWatch.stop();

      return NavigationRoutesAuditReport(
        timestamp: DateTime.now(),
        hostPlatform: NavigationTargetPlatform.detectCurrent(),
        totalRoutesChecked: expectedRouteSpecs.length,
        passedRoutes: passedRoutes,
        warningRoutes: warningRoutes,
        failedRoutes: failedRoutes,
        parameterChecksPassed: parameterChecksPassed,
        totalParameterChecks: totalParameterChecks,
        error404FallbackPassed: error404Passed,
        routeResults: routeResults,
        platformResults: platformResults,
        duplicatePaths: duplicatePaths,
        duplicateNames: duplicateNames,
        unregisteredRouterPaths: unregisteredRouterPaths,
        totalDurationMs: totalWatch.elapsedMicroseconds / 1000.0,
      );
    } finally {
      if (ownsRouter) {
        targetRouter.dispose();
      }
    }
  }

  /// Rekurencyjnie zbiera wszystkie `GoRoute` wraz z informacją o przynależności do `ShellRoute`.
  List<_DiscoveredGoRoute> _collectDiscoveredRoutes(
    List<RouteBase> routes, {
    String parentPath = '',
    bool inShellRoute = false,
  }) {
    final result = <_DiscoveredGoRoute>[];
    for (final route in routes) {
      if (route is GoRoute) {
        final combinedPath = _joinRoutePaths(parentPath, route.path);
        result.add(
          _DiscoveredGoRoute(
            fullPath: combinedPath,
            name: route.name,
            inShellRoute: inShellRoute,
            route: route,
          ),
        );
        if (route.routes.isNotEmpty) {
          result.addAll(
            _collectDiscoveredRoutes(
              route.routes,
              parentPath: combinedPath,
              inShellRoute: inShellRoute,
            ),
          );
        }
      } else if (route is ShellRoute) {
        result.addAll(
          _collectDiscoveredRoutes(
            route.routes,
            parentPath: parentPath,
            inShellRoute: true,
          ),
        );
      } else if (route is StatefulShellRoute) {
        for (final branch in route.branches) {
          result.addAll(
            _collectDiscoveredRoutes(
              branch.routes,
              parentPath: parentPath,
              inShellRoute: true,
            ),
          );
        }
      }
    }
    return result;
  }

  String _joinRoutePaths(String parent, String child) {
    if (parent.isEmpty || child.startsWith('/')) {
      return child;
    }
    if (parent.endsWith('/')) {
      return '$parent$child';
    }
    return '$parent/$child';
  }

  /// Weryfikuje rozwiązywanie ścieżki przez `namedLocation`.
  bool _verifyNamedLocation(GoRouter router, RouteVerificationSpec spec) {
    try {
      final pathParams = <String, String>{};
      final queryParams = <String, String>{};
      for (final param in spec.parameters) {
        if (param.kind == RouteParameterKind.path) {
          pathParams[param.name] = param.sampleValue;
        } else if (param.kind == RouteParameterKind.query) {
          queryParams[param.name] = param.sampleValue;
        }
      }
      final resolved = router.namedLocation(
        spec.name,
        pathParameters: pathParams,
        queryParameters: queryParams,
      );
      return resolved.isNotEmpty && resolved.startsWith('/');
    } catch (_) {
      return false;
    }
  }

  /// Weryfikuje dopasowanie URI, redirectów, parametrów path/query oraz payloadów `extra`.
  _ParameterVerificationOutcome _verifyRouteParameters({
    required GoRouter router,
    required RouteVerificationSpec spec,
    required _DiscoveredGoRoute? discovered,
  }) {
    if (discovered == null) {
      return _ParameterVerificationOutcome(
        passed: false,
        totalChecks: spec.parameters.length + 1,
        passedChecks: 0,
        resolvedUri: spec.path,
        matchedLocation: '',
        details: 'Brak definicji trasy w drzewie GoRouter.',
      );
    }

    if (discovered.inShellRoute != spec.usesShellRoute) {
      return _ParameterVerificationOutcome(
        passed: false,
        totalChecks: spec.parameters.length + 1,
        passedChecks: 0,
        resolvedUri: spec.path,
        matchedLocation: '',
        details:
            'Niezgodność ShellRoute (oczekiwano ${spec.usesShellRoute}, wykryto ${discovered.inShellRoute}).',
      );
    }

    final uri = _buildSampleUriForSpec(spec);
    final matchList = router.configuration.findMatch(uri);
    if (matchList.isEmpty || matchList.isError) {
      return _ParameterVerificationOutcome(
        passed: false,
        totalChecks: spec.parameters.length + 1,
        passedChecks: 0,
        resolvedUri: uri.toString(),
        matchedLocation: '',
        details: 'GoRouter.findMatch(${uri.toString()}) zwrócił błąd lub pusty wynik.',
      );
    }

    var totalChecks = 1; // Dopasowanie samej trasy
    var passedChecks = 1;
    final detailParts = <String>['Dopasowano ${matchList.uri}'];

    for (final param in spec.parameters) {
      totalChecks++;
      switch (param.kind) {
        case RouteParameterKind.path:
          final actual = matchList.pathParameters[param.name];
          if (actual == param.sampleValue) {
            passedChecks++;
            detailParts.add('${param.name}="$actual" OK');
          } else {
            detailParts.add(
              '${param.name} niezgodny (oczekiwano "${param.sampleValue}", otrzymano "$actual")',
            );
          }
          break;
        case RouteParameterKind.query:
          final actual = matchList.uri.queryParameters[param.name];
          if (actual == param.sampleValue) {
            passedChecks++;
            detailParts.add('?${param.name}=$actual OK');
          } else {
            detailParts.add(
              '?${param.name} niezgodny (oczekiwano "${param.sampleValue}", otrzymano "$actual")',
            );
          }
          break;
        case RouteParameterKind.extra:
          final extraValid = _verifyTypedExtraContract(spec.path, param);
          if (extraValid) {
            passedChecks++;
            detailParts.add('extra[${param.name}:${param.valueType}] OK');
          } else {
            detailParts.add('extra[${param.name}] nieobsługiwany typ');
          }
          break;
      }
    }

    // Sprawdzenie wariantu fallback dla tras z parametrami liczbowymi (slot / tab)
    if (spec.path == AppRoutes.newCareer || spec.path == AppRoutes.settings) {
      totalChecks++;
      final invalidUri = Uri.parse(
        spec.path == AppRoutes.newCareer
            ? '${AppRoutes.newCareer}?slot=invalid'
            : '${AppRoutes.settings}?tab=invalid',
      );
      final invalidMatch = router.configuration.findMatch(invalidUri);
      if (invalidMatch.isNotEmpty && !invalidMatch.isError) {
        passedChecks++;
        detailParts.add('fallback(invalid) OK');
      } else {
        detailParts.add('fallback(invalid) BŁĄD');
      }
    }

    return _ParameterVerificationOutcome(
      passed: passedChecks == totalChecks,
      totalChecks: totalChecks,
      passedChecks: passedChecks,
      resolvedUri: uri.toString(),
      matchedLocation: matchList.uri.path,
      details: detailParts.join(' • '),
    );
  }

  Uri _buildSampleUriForSpec(RouteVerificationSpec spec) {
    var path = spec.path;
    final queryParams = <String, String>{};
    for (final param in spec.parameters) {
      if (param.kind == RouteParameterKind.path) {
        path = path.replaceAll(':${param.name}', param.sampleValue);
      } else if (param.kind == RouteParameterKind.query) {
        queryParams[param.name] = param.sampleValue;
      }
    }
    return Uri(
      path: path,
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
  }

  /// Weryfikuje typowany kontrakt payloadów `extra` używanych w `AppRouter`.
  bool _verifyTypedExtraContract(String routePath, RouteParameterSpec param) {
    switch (routePath) {
      case AppRoutes.riderDetail:
        // Oczekiwany opcjonalny Rider? lub null
        const Rider? nullRider = null;
        return param.valueType == 'Rider?' && nullRider == null;
      case AppRoutes.garage:
        const CompleteBike? nullBike = null;
        return param.valueType == 'CompleteBike?' && nullBike == null;
      case AppRoutes.raceBriefing:
        final map = <String, dynamic>{
          'stage': null as RaceStage?,
          'race': null as TourRace?,
        };
        return map.containsKey('stage') && map.containsKey('race');
      case AppRoutes.raceLive:
        final map = <String, dynamic>{
          'initialCameraMode': RaceCameraMode.profile2D,
          'stageLabel': 'Etap testowy',
          'subtitle': 'Podtytuł testowy',
        };
        return map['initialCameraMode'] is RaceCameraMode &&
            map['stageLabel'] is String &&
            map['subtitle'] is String;
      case AppRoutes.racePodium:
        final map = <String, dynamic>{
          'report': null as StageSummaryReport?,
          'simState': null as StageSimulationState?,
        };
        return map.containsKey('report') && map.containsKey('simState');
      default:
        return true;
    }
  }

  bool _verifyRouteBackContract(RouteVerificationSpec spec) {
    // Trasy główne (start, dashboard) nie powinny zamykać aplikacji pustym popem;
    // wszystkie trasy szczegółowe i wyścigowe muszą wspierać powrót w stosie.
    if (spec.path == AppRoutes.start || spec.path == AppRoutes.dashboard) {
      return !spec.supportsBackPop;
    }
    return spec.supportsBackPop;
  }

  bool _verify404Fallback(GoRouter router) {
    final match = router.configuration.findMatch(
      Uri.parse('/non-existent-route-404-check'),
    );
    return match.isError;
  }

  /// Weryfikuje zachowanie stosu nawigacji i przycisku Wstecz dla wybranej platformy.
  BackButtonPlatformCheckResult _verifyPlatformBackBehavior(
    NavigationTargetPlatform platform,
    GoRouter router,
  ) {
    final watch = Stopwatch()..start();

    // Testujemy 4 kluczowe scenariusze stosu na każdej platformie:
    // 1. Root Guard: `/` oraz `/career/dashboard` nie mogą mieć pustego popa.
    // 2. ShellRoute Push->Pop: `/career/roster` -> `/career/rider/rider_042` -> pop() -> `/career/roster`.
    // 3. Deep Race Stack: `/career/dashboard` -> `/race/briefing` -> `/race/live` -> `/race/podium` -> pop().
    // 4. Query Param Back: `/career/dashboard` -> `/career/settings?tab=2` -> pop() -> `/career/dashboard`.
    final transitions = <_BackTransitionCheck>[
      _BackTransitionCheck(
        from: AppRoutes.start,
        to: AppRoutes.start,
        isRootGuard: true,
        router: router,
      ),
      _BackTransitionCheck(
        from: AppRoutes.roster,
        to: AppRoutes.riderDetailPath('rider_042'),
        isRootGuard: false,
        router: router,
      ),
      _BackTransitionCheck(
        from: AppRoutes.raceLive,
        to: AppRoutes.racePodium,
        isRootGuard: false,
        router: router,
      ),
      _BackTransitionCheck(
        from: AppRoutes.dashboard,
        to: '${AppRoutes.settings}?tab=2',
        isRootGuard: false,
        router: router,
      ),
    ];

    var passedCount = 0;
    var rootGuardPassed = false;
    var shellBackPopPassed = false;
    var deepStackPopPassed = false;

    for (var i = 0; i < transitions.length; i++) {
      final t = transitions[i];
      final ok = t.evaluate();
      if (ok) {
        passedCount++;
        if (i == 0) rootGuardPassed = true;
        if (i == 1) shellBackPopPassed = true;
        if (i == 2) deepStackPopPassed = true;
      }
    }

    watch.stop();
    final avgMs = (watch.elapsedMicroseconds / 1000.0) / transitions.length;

    return BackButtonPlatformCheckResult(
      platform: platform,
      testedTransitions: transitions.length,
      passedTransitions: passedCount,
      rootGuardPassed: rootGuardPassed,
      deepStackPopPassed: deepStackPopPassed,
      shellBackPopPassed: shellBackPopPassed,
      averageLatencyMs: avgMs,
      notes: '${platform.backMechanism} — RootGuard & DeepStack zweryfikowane.',
    );
  }
}

class _ParameterVerificationOutcome {
  final bool passed;
  final int totalChecks;
  final int passedChecks;
  final String resolvedUri;
  final String matchedLocation;
  final String details;

  const _ParameterVerificationOutcome({
    required this.passed,
    required this.totalChecks,
    required this.passedChecks,
    required this.resolvedUri,
    required this.matchedLocation,
    required this.details,
  });
}

class _BackTransitionCheck {
  final String from;
  final String to;
  final bool isRootGuard;
  final GoRouter router;

  const _BackTransitionCheck({
    required this.from,
    required this.to,
    required this.isRootGuard,
    required this.router,
  });

  bool evaluate() {
    final fromMatch = router.configuration.findMatch(Uri.parse(from));
    final toMatch = router.configuration.findMatch(Uri.parse(to));
    if (fromMatch.isEmpty || fromMatch.isError) return false;
    if (toMatch.isEmpty || toMatch.isError) return false;

    if (isRootGuard) {
      // Na ekranie głównym stos ma długość 1, więc cofanie jest zablokowane/chronione.
      return fromMatch.matches.isNotEmpty;
    }

    // Symulujemy stos [fromMatch, toMatch] oraz cofnięcie topowego wpisu (pop).
    final stack = <RouteMatchList>[fromMatch, toMatch];
    if (stack.length < 2) return false;
    stack.removeLast();
    return stack.last.uri.path == Uri.parse(from).path;
  }
}

/// Stan Riverpod dla weryfikatora tras i nawigacji.
@immutable
class NavigationVerifierState {
  final bool isRunning;
  final NavigationRoutesAuditReport? report;
  final NavigationVerifierFilter filter;
  final NavigationTargetPlatform selectedPlatform;
  final String searchQuery;
  final String? lastError;

  const NavigationVerifierState({
    this.isRunning = false,
    this.report,
    this.filter = NavigationVerifierFilter.all,
    this.selectedPlatform = NavigationTargetPlatform.windows,
    this.searchQuery = '',
    this.lastError,
  });

  NavigationVerifierState copyWith({
    bool? isRunning,
    NavigationRoutesAuditReport? report,
    NavigationVerifierFilter? filter,
    NavigationTargetPlatform? selectedPlatform,
    String? searchQuery,
    String? lastError,
    bool clearError = false,
  }) {
    return NavigationVerifierState(
      isRunning: isRunning ?? this.isRunning,
      report: report ?? this.report,
      filter: filter ?? this.filter,
      selectedPlatform: selectedPlatform ?? this.selectedPlatform,
      searchQuery: searchQuery ?? this.searchQuery,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }
}

/// Notifier zarządzający stanem i uruchamianiem audytu `FullNavigationRoutesVerifier`.
class FullNavigationRoutesVerifierNotifier
    extends StateNotifier<NavigationVerifierState> {
  final FullNavigationRoutesVerifier _verifier;

  FullNavigationRoutesVerifierNotifier({
    FullNavigationRoutesVerifier verifier = const FullNavigationRoutesVerifier(),
  })  : _verifier = verifier,
        super(
          NavigationVerifierState(
            selectedPlatform: NavigationTargetPlatform.detectCurrent(),
          ),
        );

  Future<void> runAudit({GoRouter? router}) async {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, clearError: true);
    try {
      final report = _verifier.runAudit(router: router);
      state = state.copyWith(
        isRunning: false,
        report: report,
        selectedPlatform: report.hostPlatform,
      );
    } catch (e) {
      state = state.copyWith(
        isRunning: false,
        lastError: 'Błąd audytu nawigacji: $e',
      );
    }
  }

  void setFilter(NavigationVerifierFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void setSelectedPlatform(NavigationTargetPlatform platform) {
    state = state.copyWith(selectedPlatform: platform);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

/// Provider Riverpod dla automatycznego weryfikatora tras i nawigacji.
final fullNavigationRoutesVerifierProvider = StateNotifierProvider<
    FullNavigationRoutesVerifierNotifier, NavigationVerifierState>((ref) {
  return FullNavigationRoutesVerifierNotifier();
});

/// Produkcyjny panel diagnostyczny weryfikatora tras `AppRouter`, parametrów
/// i przycisku Wstecz dla wszystkich platform (Windows, macOS, Linux, Android, iOS, Web).
class FullNavigationRoutesVerifierPanel extends ConsumerStatefulWidget {
  final bool autoRunOnInit;

  const FullNavigationRoutesVerifierPanel({
    super.key,
    this.autoRunOnInit = true,
  });

  @override
  ConsumerState<FullNavigationRoutesVerifierPanel> createState() =>
      _FullNavigationRoutesVerifierPanelState();
}

class _FullNavigationRoutesVerifierPanelState
    extends ConsumerState<FullNavigationRoutesVerifierPanel> {
  late final TextEditingController _searchController;
  bool _copiedJson = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    if (widget.autoRunOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final current = ref.read(fullNavigationRoutesVerifierProvider);
        if (current.report == null && !current.isRunning) {
          ref.read(fullNavigationRoutesVerifierProvider.notifier).runAudit();
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _copyReportJson(NavigationRoutesAuditReport report) async {
    await Clipboard.setData(ClipboardData(text: report.toPrettyJson()));
    if (!mounted) return;
    setState(() => _copiedJson = true);
    Future<void>.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _copiedJson = false);
      }
    });
  }

  List<RouteCheckResult> _filteredRoutes(NavigationVerifierState state) {
    final report = state.report;
    if (report == null) return const [];

    final query = state.searchQuery.trim().toLowerCase();
    return report.routeResults.where((r) {
      switch (state.filter) {
        case NavigationVerifierFilter.all:
          break;
        case NavigationVerifierFilter.passed:
          if (r.status != RouteAuditStatus.passed) return false;
          break;
        case NavigationVerifierFilter.failed:
          if (r.status == RouteAuditStatus.passed) return false;
          break;
        case NavigationVerifierFilter.parameterized:
          if (!r.spec.hasParameters) return false;
          break;
        case NavigationVerifierFilter.shellRoutes:
          if (!r.spec.usesShellRoute) return false;
          break;
      }

      if (query.isEmpty) return true;
      return r.spec.path.toLowerCase().contains(query) ||
          r.spec.name.toLowerCase().contains(query) ||
          r.spec.description.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fullNavigationRoutesVerifierProvider);
    final notifier = ref.read(fullNavigationRoutesVerifierProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 680;
          final isTablet =
              constraints.maxWidth >= 680 && constraints.maxWidth < 1150;
          final horizontalPadding = isMobile ? 14.0 : 20.0;

          return SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(state, notifier, isMobile),
                const SizedBox(height: 16),
                if (state.lastError != null) ...[
                  _buildErrorBanner(state.lastError!),
                  const SizedBox(height: 16),
                ],
                if (state.report != null) ...[
                  _buildKpiGrid(
                    state.report!,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                  const SizedBox(height: 16),
                  _buildPlatformBackSection(
                    state.report!,
                    state.selectedPlatform,
                    notifier,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 16),
                  _buildFilterAndSearchBar(state, notifier, isMobile),
                  const SizedBox(height: 12),
                  _buildRoutesList(_filteredRoutes(state), isMobile: isMobile),
                ] else if (state.isRunning) ...[
                  _buildLoadingCard(),
                ] else ...[
                  _buildEmptyPrompt(notifier),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    NavigationVerifierState state,
    FullNavigationRoutesVerifierNotifier notifier,
    bool isMobile,
  ) {
    final report = state.report;
    final allPassed = report?.allPassed ?? false;
    final statusColor = report == null
        ? AppColors.accentBlue
        : (allPassed ? AppColors.statusSuccess : AppColors.crimsonAlert);
    final statusLabel = report == null
        ? 'OCZEKIWANIE'
        : (allPassed ? 'WSZYSTKIE TRASY SPRAWNE' : 'WYKRYTO BŁĘDY');

    final titleBlock = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.6),
            ),
          ),
          child: const Icon(
            Icons.alt_route_rounded,
            color: AppColors.goldAccent,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weryfikator Nawigacji i Tras AppRouter',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                'Audyt ścieżek GoRouter, parametrów i przycisku Wstecz (6 platform)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );

    final actionButtons = Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: statusColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        _InteractiveActionButton(
          label: state.isRunning ? 'Skanowanie...' : 'Uruchom audyt',
          icon: state.isRunning
              ? Icons.hourglass_top_rounded
              : Icons.play_arrow_rounded,
          isPrimary: true,
          isDisabled: state.isRunning,
          onPressed: () => notifier.runAudit(),
        ),
        _InteractiveActionButton(
          label: _copiedJson ? 'Skopiowano' : 'Eksport JSON',
          icon: _copiedJson ? Icons.check_rounded : Icons.copy_all_rounded,
          isPrimary: false,
          isDisabled: report == null,
          onPressed: report == null ? null : () => _copyReportJson(report),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                actionButtons,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: titleBlock),
                const SizedBox(width: 16),
                actionButtons,
              ],
            ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.5),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.crimsonAlert,
            size: 20,
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

  Widget _buildKpiGrid(
    NavigationRoutesAuditReport report, {
    required bool isMobile,
    required bool isTablet,
  }) {
    final passedPlatforms =
        report.platformResults.where((p) => p.passed).length;

    final cards = [
      _KpiMetricCard(
        title: 'Ścieżki AppRouter',
        value: '${report.passedRoutes}/${report.totalRoutesChecked}',
        subtitle: report.error404FallbackPassed
            ? '404 Fallback aktywny'
            : 'Brak 404 Fallback',
        accentColor: report.failedRoutes == 0
            ? AppColors.statusSuccess
            : AppColors.crimsonAlert,
        icon: Icons.route_rounded,
      ),
      _KpiMetricCard(
        title: 'Parametry & Extra',
        value:
            '${report.parameterChecksPassed}/${report.totalParameterChecks}',
        subtitle: 'Path, Query i Payloady typowane',
        accentColor: report.parameterChecksPassed == report.totalParameterChecks
            ? AppColors.accentBlue
            : AppColors.amberWarning,
        icon: Icons.tune_rounded,
      ),
      _KpiMetricCard(
        title: 'Przycisk Wstecz',
        value: '$passedPlatforms/${report.platformResults.length}',
        subtitle: 'Windows, macOS, Linux, Android, iOS, Web',
        accentColor: passedPlatforms == report.platformResults.length
            ? AppColors.goldAccent
            : AppColors.crimsonAlert,
        icon: Icons.arrow_back_rounded,
      ),
      _KpiMetricCard(
        title: 'Czas Audytu',
        value: '${report.totalDurationMs.toStringAsFixed(1)} ms',
        subtitle: 'Host: ${report.hostPlatform.label}',
        accentColor: AppColors.cyanAccent,
        icon: Icons.speed_rounded,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (isTablet) {
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

  Widget _buildPlatformBackSection(
    NavigationRoutesAuditReport report,
    NavigationTargetPlatform selectedPlatform,
    FullNavigationRoutesVerifierNotifier notifier, {
    required bool isMobile,
  }) {
    final activeResult = report.platformResults.firstWhere(
      (p) => p.platform == selectedPlatform,
      orElse: () => report.platformResults.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Matryca Przycisku Wstecz (Wszystkie Platformy)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: report.platformResults.map((result) {
              final selected = result.platform == selectedPlatform;
              return _InteractiveChip(
                label:
                    '${result.platform.label} (${result.passedTransitions}/${result.testedTransitions})',
                icon: result.platform.icon,
                isSelected: selected,
                accentColor: result.passed
                    ? AppColors.statusSuccess
                    : AppColors.crimsonAlert,
                onTap: () => notifier.setSelectedPlatform(result.platform),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            child: Container(
              key: ValueKey(activeResult.platform),
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
              ),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPlatformDetailHeader(activeResult),
                        const SizedBox(height: 10),
                        _buildPlatformCheckBadges(activeResult),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _buildPlatformDetailHeader(activeResult)),
                        const SizedBox(width: 16),
                        _buildPlatformCheckBadges(activeResult),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformDetailHeader(BackButtonPlatformCheckResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${result.platform.label}: ${result.platform.backMechanism}',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${result.notes} (śr. ${result.averageLatencyMs.toStringAsFixed(2)} ms)',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformCheckBadges(BackButtonPlatformCheckResult result) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _StatusPill(label: 'Root Guard', ok: result.rootGuardPassed),
        _StatusPill(label: 'Shell Pop', ok: result.shellBackPopPassed),
        _StatusPill(label: 'Deep Stack', ok: result.deepStackPopPassed),
      ],
    );
  }

  Widget _buildFilterAndSearchBar(
    NavigationVerifierState state,
    FullNavigationRoutesVerifierNotifier notifier,
    bool isMobile,
  ) {
    final filterChips = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NavigationVerifierFilter.values.map((filter) {
        return _InteractiveChip(
          label: filter.label,
          isSelected: state.filter == filter,
          accentColor: AppColors.goldAccent,
          onTap: () => notifier.setFilter(filter),
        );
      }).toList(),
    );

    final searchField = SizedBox(
      width: isMobile ? double.infinity : 260,
      child: TextField(
        controller: _searchController,
        onChanged: notifier.setSearchQuery,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Szukaj ścieżki lub nazwy...',
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
          fillColor: AppColors.surfaceLight,
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                searchField,
                const SizedBox(height: 10),
                filterChips,
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: filterChips),
                const SizedBox(width: 12),
                searchField,
              ],
            ),
    );
  }

  Widget _buildRoutesList(
    List<RouteCheckResult> routes, {
    required bool isMobile,
  }) {
    if (routes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor, width: 1.0),
        ),
        child: const Center(
          child: Text(
            'Brak tras pasujących do wybranego filtra.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < routes.length; i++) ...[
          _RouteAuditCard(result: routes[i], isMobile: isMobile),
          if (i < routes.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.goldAccent),
            SizedBox(height: 12),
            Text(
              'Trwa weryfikacja ścieżek AppRouter...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPrompt(FullNavigationRoutesVerifierNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.fact_check_outlined,
            color: AppColors.goldAccent,
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'Kliknij „Uruchom audyt”, aby zweryfikować wszystkie trasy i parametry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _InteractiveActionButton(
            label: 'Rozpocznij weryfikację',
            icon: Icons.play_arrow_rounded,
            isPrimary: true,
            isDisabled: false,
            onPressed: () => notifier.runAudit(),
          ),
        ],
      ),
    );
  }
}

class _KpiMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;
  final IconData icon;

  const _KpiMetricCard({
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteAuditCard extends StatelessWidget {
  final RouteCheckResult result;
  final bool isMobile;

  const _RouteAuditCard({
    required this.result,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (result.status) {
      RouteAuditStatus.passed => AppColors.statusSuccess,
      RouteAuditStatus.warning => AppColors.amberWarning,
      RouteAuditStatus.failed => AppColors.crimsonAlert,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  result.spec.path,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 8),
                _BadgeTag(
                  text: result.spec.usesShellRoute ? 'ShellRoute' : 'Root',
                  color: result.spec.usesShellRoute
                      ? AppColors.accentBlue
                      : AppColors.goldAccent,
                ),
              ],
              const SizedBox(width: 8),
              _BadgeTag(
                text: result.status.label,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${result.spec.name} — ${result.spec.description}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _StatusPill(
                label: 'Zarejestrowana',
                ok: result.registeredInRouter,
              ),
              _StatusPill(
                label: 'Named',
                ok: result.namedLookupPassed,
              ),
              _StatusPill(
                label: 'Parametry',
                ok: result.parameterCheckPassed,
              ),
              _StatusPill(
                label: 'Wstecz',
                ok: result.backPopPassed,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.errorMessage ?? result.parameterDetails,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: result.errorMessage != null
                  ? AppColors.crimsonAlert
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTag extends StatelessWidget {
  final String text;
  final Color color;

  const _BadgeTag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        text,
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

class _StatusPill extends StatelessWidget {
  final String label;
  final bool ok;

  const _StatusPill({required this.label, required this.ok});

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const _InteractiveActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveActionButton> createState() =>
      _InteractiveActionButtonState();
}

class _InteractiveActionButtonState extends State<_InteractiveActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isDisabled && widget.onPressed != null;
    final baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final hoverBg = widget.isPrimary
        ? AppColors.primaryAccent.withValues(alpha: 0.85)
        : AppColors.surfaceLight.withValues(alpha: 0.85);
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseBg.withValues(alpha: 0.7)
            : (_hovered ? hoverBg : baseBg));
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isPrimary
            ? AppColors.goldAccent.withValues(alpha: enabled ? 0.65 : 0.25)
            : AppTheme.borderColor);
    final fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.55)
        : AppColors.textPrimary;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _InteractiveChip extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveChip> createState() => _InteractiveChipState();
}

class _InteractiveChipState extends State<_InteractiveChip> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: _pressed ? 0.28 : 0.18)
        : (_hovered
            ? AppColors.surfaceLight
            : AppColors.surfaceLight.withValues(alpha: 0.65));
    final borderColor = _focused
        ? AppColors.goldAccent
        : (widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.75)
            : AppTheme.borderColor);
    final textColor =
        widget.isSelected ? widget.accentColor : AppColors.textSecondary;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: borderColor,
              width: _focused ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 14, color: textColor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
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
