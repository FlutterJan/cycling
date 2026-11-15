import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/app_localizations_pl_en.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/performance_profiler_overlay.dart';
import 'state/game_settings_notifier.dart';
import 'ui/widgets/achievement_unlock_toast_overlay.dart';

/// Punkt startowy gry Pro Peloton Manager.
/// Inicjalizuje platformy (iOS, Android, macOS, Windows), Riverpod ProviderScope,
/// ciemny motyw kolarstwa zawodowego oraz deklaratywny router GoRouter.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Konfiguracja nakładki systemowej (status bar i pasek nawigacji) dla iOS i Android
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Zezwolenie na elastyczną orientację ekranu (responsywność dla telefonów, tabletów i monitorów PC/Mac)
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  } catch (_) {
    // Niektóre platformy desktopowe ignorują orientację
  }

  // Globalny filtr błędów dla renderera Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('[ProPelotonManager Error]: ${details.exceptionAsString()}');
    }
  };

  runApp(
    const ProviderScope(
      child: ProPelotonManagerApp(),
    ),
  );
}

/// Główny widżet aplikacji spinający Theme, GoRouter i właściwości wieloplatformowe.
class ProPelotonManagerApp extends ConsumerWidget {
  const ProPelotonManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final localizations = ref.watch(appLocalizationsProvider);

    return MaterialApp.router(
      title: 'Pro Peloton Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      scrollBehavior: const AppScrollBehavior(),
      builder: (context, child) {
        return AppLocalizationsScope(
          localizations: localizations,
          child: MediaQuery(
            // Zabezpieczenie przed ekstremalnym skalowaniem czcionek w ustawieniach systemu
            data: MediaQuery.of(context).copyWith(
              textScaler: MediaQuery.of(context).textScaler.clamp(
                    minScaleFactor: 0.85,
                    maxScaleFactor: 1.15,
                  ),
            ),
            child: PerformanceProfilerOverlay(
              child: AchievementUnlockToastOverlay(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Zachowanie przewijania z obsługą myszy, gładzika i ekranu dotykowego
/// dla środowisk desktopowych (macOS, Windows) oraz mobilnych (iOS, Android).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
