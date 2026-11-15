import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';
import '../../engine/rendering3d/camera_rig_controller.dart';
import '../../engine/simulation/stage_simulation_loop.dart';
import '../../state/career_controller.dart';
import '../../state/race_simulation_notifier.dart';

/// Kontekst aktywnych skrótów klawiszowych.
enum ShortcutContextMode {
  /// Tryb menedżera (pulpit, kalendarz, kadra, finanse).
  manager,

  /// Tryb symulacji wyścigu 3D i HUD live.
  race3d,

  /// Wszystkie skróty aktywne jednocześnie (np. globalny wrapper lub testy).
  both,
}

/// Grupy tematyczne wyświetlane w modalu ściągi skrótów (`ShortcutsCheatSheetOverlay`).
enum ShortcutCategory {
  raceTimeAndCamera(
    title: 'Wyścig 3D — Czas i Kamera',
    icon: Icons.videocam_rounded,
    accentColor: AppColors.cyanAccent,
  ),
  raceTacticsAndNutrition(
    title: 'Rozkazy Taktyczne i Żywienie',
    icon: Icons.bolt_rounded,
    accentColor: AppColors.goldAccent,
  ),
  riderSelection(
    title: 'Wybór Kolarza (1–8)',
    icon: Icons.directions_bike_rounded,
    accentColor: AppColors.accentBlue,
  ),
  managerAndSystem(
    title: 'Tryb Menedżera i System',
    icon: Icons.dashboard_customize_rounded,
    accentColor: AppColors.statusSuccess,
  );

  final String title;
  final IconData icon;
  final Color accentColor;

  const ShortcutCategory({
    required this.title,
    required this.icon,
    required this.accentColor,
  });
}

/// Definicja pojedynczego skrótu klawiszowego wyświetlana w ściągawce.
@immutable
class ShortcutDefinition {
  final String id;
  final List<String> keyCaps;
  final String label;
  final String description;
  final ShortcutCategory category;
  final IconData icon;
  final bool isRaceOnly;
  final bool isManagerOnly;

  const ShortcutDefinition({
    required this.id,
    required this.keyCaps,
    required this.label,
    required this.description,
    required this.category,
    required this.icon,
    this.isRaceOnly = false,
    this.isManagerOnly = false,
  });
}

/// Katalog wszystkich obsługiwanych skrótów klawiszowych w Pro Peloton Manager.
class KeyboardShortcutsCatalog {
  KeyboardShortcutsCatalog._();

  static const List<ShortcutDefinition> all = [
    // 1. Wyścig 3D — Czas i Kamera
    ShortcutDefinition(
      id: 'race_pause',
      keyCaps: ['Spacja'],
      label: 'Pauza / Wznów',
      description: 'Zatrzymuje lub wznawia symulację wyścigu 3D.',
      category: ShortcutCategory.raceTimeAndCamera,
      icon: Icons.pause_circle_outline_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'race_speed_up',
      keyCaps: ['+', ']'],
      label: 'Przyspiesz czas',
      description: 'Zwiększa mnożnik prędkości symulacji (1x → 2x → 4x → 8x).',
      category: ShortcutCategory.raceTimeAndCamera,
      icon: Icons.fast_forward_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'race_speed_down',
      keyCaps: ['-', '['],
      label: 'Zwolnij czas',
      description: 'Zmniejsza mnożnik prędkości symulacji (8x → 4x → 2x → 1x).',
      category: ShortcutCategory.raceTimeAndCamera,
      icon: Icons.fast_rewind_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'race_cycle_camera',
      keyCaps: ['C'],
      label: 'Przełącz kamerę 3D',
      description:
          'Cyklicznie zmienia ujęcie: ChaseCam → MotoTvCam → HeliCam → FinishLineCam.',
      category: ShortcutCategory.raceTimeAndCamera,
      icon: Icons.cameraswitch_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'race_aero_vision',
      keyCaps: ['V'],
      label: 'Aero Vision Mode',
      description: 'Włącza lub wyłącza wizualizację strug powietrza i cienia aero.',
      category: ShortcutCategory.raceTimeAndCamera,
      icon: Icons.air_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'race_toggle_hud',
      keyCaps: ['Tab'],
      label: 'Pokaż / Ukryj panele HUD',
      description: 'Chowa lub odsłania boczne panele telemetrii dla czystego widoku 3D.',
      category: ShortcutCategory.raceTimeAndCamera,
      icon: Icons.visibility_off_outlined,
      isRaceOnly: true,
    ),

    // 2. Rozkazy Taktyczne i Żywienie
    ShortcutDefinition(
      id: 'tactic_attack',
      keyCaps: ['A'],
      label: 'Natychmiastowy atak',
      description: 'Wydaje wybranemu kolarzowi rozkaz oderwania się od grupy.',
      category: ShortcutCategory.raceTacticsAndNutrition,
      icon: Icons.flash_on_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'tactic_pull',
      keyCaps: ['R'],
      label: 'Zmiana na czele',
      description: 'Kolarz wychodzi na czoło grupy i nadaje tempo (Pull Group).',
      category: ShortcutCategory.raceTacticsAndNutrition,
      icon: Icons.trending_up_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'tactic_protect',
      keyCaps: ['P'],
      label: 'Chroń lidera',
      description: 'Kolarz osłania lidera drużyny przed wiatrem i atakami.',
      category: ShortcutCategory.raceTacticsAndNutrition,
      icon: Icons.shield_outlined,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'nutrition_gel',
      keyCaps: ['G'],
      label: 'Spożyj żel energetyczny',
      description: 'Podaje żel węglowodanowy wybranemu kolarzowi.',
      category: ShortcutCategory.raceTacticsAndNutrition,
      icon: Icons.local_fire_department_rounded,
      isRaceOnly: true,
    ),
    ShortcutDefinition(
      id: 'nutrition_bidons',
      keyCaps: ['B'],
      label: 'Spłyń po bidony',
      description: 'Wysyła kolarza do wozu technicznego po bidony dla drużyny.',
      category: ShortcutCategory.raceTacticsAndNutrition,
      icon: Icons.water_drop_outlined,
      isRaceOnly: true,
    ),

    // 3. Wybór Kolarza (1–8)
    ShortcutDefinition(
      id: 'select_rider_1_8',
      keyCaps: ['1', '–', '8'],
      label: 'Wybór kolarza nr 1–8',
      description:
          'Wybiera kolarza z drużyny (sloty 1–8) i natychmiast centruje na nim kamerę 3D.',
      category: ShortcutCategory.riderSelection,
      icon: Icons.filter_1_rounded,
      isRaceOnly: true,
    ),

    // 4. Tryb Menedżera i System
    ShortcutDefinition(
      id: 'manager_quick_save',
      keyCaps: ['Ctrl', 'S'],
      label: 'Szybki zapis gry',
      description: 'Zapisuje bieżący stan kariery (na macOS również Cmd+S).',
      category: ShortcutCategory.managerAndSystem,
      icon: Icons.save_rounded,
      isManagerOnly: true,
    ),
    ShortcutDefinition(
      id: 'manager_advance_day',
      keyCaps: ['Enter'],
      label: 'Następny dzień (Advance Day)',
      description: 'Przechodzi do kolejnego dnia kalendarza (również Ctrl+Spacja).',
      category: ShortcutCategory.managerAndSystem,
      icon: Icons.skip_next_rounded,
      isManagerOnly: true,
    ),
    ShortcutDefinition(
      id: 'manager_advance_day_alt',
      keyCaps: ['Ctrl', 'Spacja'],
      label: 'Następny dzień (Alternatywny)',
      description: 'Bezpieczny skrót przejścia do kolejnego dnia kariery.',
      category: ShortcutCategory.managerAndSystem,
      icon: Icons.calendar_today_rounded,
      isManagerOnly: true,
    ),
    ShortcutDefinition(
      id: 'system_cheatsheet',
      keyCaps: ['F1'],
      label: 'Ściąga skrótów klawiszowych',
      description: 'Otwiera lub zamyka ten panel pomocy (Esc aby zamknąć).',
      category: ShortcutCategory.managerAndSystem,
      icon: Icons.keyboard_rounded,
    ),
  ];
}

// ============================================================================
// INTENTS (Flutter Shortcuts / Actions Architecture)
// ============================================================================

/// Intencja przełączenia pauzy wyścigu.
class ToggleRacePauseIntent extends Intent {
  const ToggleRacePauseIntent();
}

/// Intencja zmiany mnożnika prędkości (+1 lub -1).
class ChangeRaceSpeedIntent extends Intent {
  final int stepDelta;
  const ChangeRaceSpeedIntent(this.stepDelta);
}

/// Intencja wyboru kolarza drużyny po indeksie 0..7 (klawisze 1–8).
class SelectTeamRiderIntent extends Intent {
  final int riderIndex;
  const SelectTeamRiderIntent(this.riderIndex);
}

/// Intencja wydania rozkazu taktycznego wybranemu kolarzowi.
class IssueRaceTacticalOrderIntent extends Intent {
  final TacticalOrder order;
  const IssueRaceTacticalOrderIntent(this.order);
}

/// Intencja podania żelu energetycznego wybranemu kolarzowi.
class ConsumeEnergyGelIntent extends Intent {
  const ConsumeEnergyGelIntent();
}

/// Intencja wysłania kolarza do wozu technicznego po bidony.
class FetchTeamBidonsIntent extends Intent {
  const FetchTeamBidonsIntent();
}

/// Intencja cyklicznego przełączenia kamery 3D.
class CycleRaceCameraIntent extends Intent {
  const CycleRaceCameraIntent();
}

/// Intencja przełączenia trybu Aero Vision.
class ToggleAeroVisionIntent extends Intent {
  const ToggleAeroVisionIntent();
}

/// Intencja ukrycia/pokazania bocznych paneli HUD.
class ToggleHudPanelsIntent extends Intent {
  const ToggleHudPanelsIntent();
}

/// Intencja szybkiego zapisu gry w trybie menedżera.
class QuickSaveGameIntent extends Intent {
  const QuickSaveGameIntent();
}

/// Intencja przejścia do kolejnego dnia kariery.
class AdvanceCareerDayIntent extends Intent {
  const AdvanceCareerDayIntent();
}

/// Intencja otwarcia/zamknięcia ściągi skrótów klawiszowych.
class ToggleShortcutsCheatSheetIntent extends Intent {
  const ToggleShortcutsCheatSheetIntent();
}

/// Intencja zamknięcia aktywnego modala skrótów.
class CloseShortcutsCheatSheetIntent extends Intent {
  const CloseShortcutsCheatSheetIntent();
}

// ============================================================================
// CONTROLLER / MANAGER WIDGET
// ============================================================================

/// Kompletny system skrótów klawiszowych i obsługi klawiatur sprzętowych dla
/// wersji Windows (`.exe`), macOS (`.dmg`) oraz tabletów z klawiaturą.
///
/// Wykorzystuje natywny mechanizm Fluttera: `Shortcuts`, `Actions`, `FocusNode`
/// oraz `HardwareKeyboard` z pełną ochroną przed przechwytywaniem podczas pisania
/// w polach tekstowych (`EditableText`).
class KeyboardShortcutsManager extends ConsumerStatefulWidget {
  /// Zawartość ekranu objęta systemem skrótów.
  final Widget child;

  /// Aktywny kontekst skrótów (wyścig 3D, menedżer lub oba).
  final ShortcutContextMode mode;

  /// Czy skróty są aktualnie aktywne.
  final bool enabled;

  /// Opcjonalny zewnętrzny `FocusNode`.
  final FocusNode? focusNode;

  /// Czy automatycznie przechwytywać fokus po zamontowaniu.
  final bool autofocus;

  // --- Opcjonalne callbacki wyścigu 3D (nadpisują domyślne wywołania Riverpod) ---
  final VoidCallback? onTogglePause;
  final ValueChanged<SimulationTimeSpeed>? onSpeedChanged;
  final ValueChanged<int>? onSelectRiderBySlot;
  final void Function(String riderId, TacticalOrder order)? onTacticalOrder;
  final ValueChanged<String>? onConsumeGel;
  final ValueChanged<String>? onFetchBidons;
  final ValueChanged<RaceCameraMode>? onCameraModeChanged;
  final ValueChanged<bool>? onAeroVisionChanged;
  final ValueChanged<bool>? onHudVisibilityChanged;

  /// Początkowy tryb kamery dla cyklu `C`.
  final RaceCameraMode initialCameraMode;

  /// Początkowy stan Aero Vision dla skrótu `V`.
  final bool initialAeroVision;

  /// Początkowa widoczność bocznych paneli HUD dla skrótu `Tab`.
  final bool initialHudVisible;

  // --- Opcjonalne callbacki trybu menedżera ---
  final Future<void> Function()? onQuickSave;
  final VoidCallback? onAdvanceDay;

  /// Callback powiadomienia o wykonaniu skrótu (np. mini-toast w HUD).
  final ValueChanged<String>? onShortcutTriggeredFeedback;

  const KeyboardShortcutsManager({
    super.key,
    required this.child,
    this.mode = ShortcutContextMode.both,
    this.enabled = true,
    this.focusNode,
    this.autofocus = true,
    this.onTogglePause,
    this.onSpeedChanged,
    this.onSelectRiderBySlot,
    this.onTacticalOrder,
    this.onConsumeGel,
    this.onFetchBidons,
    this.onCameraModeChanged,
    this.onAeroVisionChanged,
    this.onHudVisibilityChanged,
    this.initialCameraMode = RaceCameraMode.chaseCam,
    this.initialAeroVision = false,
    this.initialHudVisible = true,
    this.onQuickSave,
    this.onAdvanceDay,
    this.onShortcutTriggeredFeedback,
  });

  /// Programatycznie otwiera modal ściągi skrótów w dowolnym miejscu aplikacji.
  static Future<void> showCheatSheet(
    BuildContext context, {
    ShortcutContextMode mode = ShortcutContextMode.both,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Zamknij ściągę skrótów',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return ShortcutsCheatSheetOverlay(
          activeMode: mode,
          onClose: () => Navigator.of(dialogContext).maybePop(),
        );
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<KeyboardShortcutsManager> createState() =>
      _KeyboardShortcutsManagerState();
}

class _KeyboardShortcutsManagerState
    extends ConsumerState<KeyboardShortcutsManager> {
  late FocusNode _focusNode;
  bool _ownsFocusNode = false;

  bool _isCheatSheetVisible = false;
  late RaceCameraMode _currentCameraMode;
  late bool _isAeroVisionActive;
  late bool _isHudVisible;

  static const List<SimulationTimeSpeed> _speedSteps = [
    SimulationTimeSpeed.x1,
    SimulationTimeSpeed.x2,
    SimulationTimeSpeed.x4,
    SimulationTimeSpeed.x8,
  ];

  static const List<RaceCameraMode> _cameraCycle = [
    RaceCameraMode.chaseCam,
    RaceCameraMode.motoTvCam,
    RaceCameraMode.heliCam,
    RaceCameraMode.finishLineCam,
  ];

  @override
  void initState() {
    super.initState();
    _currentCameraMode = widget.initialCameraMode;
    _isAeroVisionActive = widget.initialAeroVision;
    _isHudVisible = widget.initialHudVisible;

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _ownsFocusNode = false;
    } else {
      _focusNode = FocusNode(debugLabel: 'KeyboardShortcutsManagerFocus');
      _ownsFocusNode = true;
    }

    HardwareKeyboard.instance.addHandler(_handleHardwareKeyEvent);
  }

  @override
  void didUpdateWidget(covariant KeyboardShortcutsManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (_ownsFocusNode) {
        _focusNode.dispose();
      }
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _ownsFocusNode = false;
      } else {
        _focusNode = FocusNode(debugLabel: 'KeyboardShortcutsManagerFocus');
        _ownsFocusNode = true;
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleHardwareKeyEvent);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  bool get _isMacOs => defaultTargetPlatform == TargetPlatform.macOS;

  bool get _raceShortcutsEnabled =>
      widget.enabled &&
      !_isCheatSheetVisible &&
      (widget.mode == ShortcutContextMode.race3d ||
          widget.mode == ShortcutContextMode.both);

  bool get _managerShortcutsEnabled =>
      widget.enabled &&
      !_isCheatSheetVisible &&
      (widget.mode == ShortcutContextMode.manager ||
          widget.mode == ShortcutContextMode.both);

  /// Sprawdza, czy użytkownik pisze aktualnie w polu tekstowym (TextField).
  bool _isTypingInEditableText() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final ctx = primaryFocus?.context;
    if (ctx == null) return false;
    if (ctx.widget is EditableText) return true;
    return ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  /// Dodatkowy handler `HardwareKeyboard` gwarantujący obsługę klawiszy
  /// niezależnie od układu znaków (np. `+` z Shift+`=`, `-`) oraz na
  /// tabletach z klawiaturą zewnętrzną.
  bool _handleHardwareKeyEvent(KeyEvent event) {
    if (!mounted || !widget.enabled) return false;
    if (event is! KeyDownEvent) return false;
    if (_isTypingInEditableText()) return false;
    if (_isCheatSheetVisible) return false;

    final logicalKey = event.logicalKey;

    // Obsługa znaków '+' / '-' (również gdy użytkownik wciska Shift + '=' na układzie US)
    if (_raceShortcutsEnabled) {
      if (logicalKey == LogicalKeyboardKey.add ||
          logicalKey == LogicalKeyboardKey.equal ||
          event.character == '+') {
        _changeSimulationSpeed(1);
        return true;
      }
      if (logicalKey == LogicalKeyboardKey.minus ||
          event.character == '-') {
        _changeSimulationSpeed(-1);
        return true;
      }
    }

    return false;
  }

  Map<ShortcutActivator, Intent> _buildShortcutMap() {
    final map = <ShortcutActivator, Intent>{
      const SingleActivator(LogicalKeyboardKey.f1):
          const ToggleShortcutsCheatSheetIntent(),
    };

    if (_isCheatSheetVisible) {
      map[const SingleActivator(LogicalKeyboardKey.escape)] =
          const CloseShortcutsCheatSheetIntent();
      return map;
    }

    if (_raceShortcutsEnabled) {
      map.addAll({
        // Pauza / Wznów
        const SingleActivator(LogicalKeyboardKey.space):
            const ToggleRacePauseIntent(),

        // Zmiana mnożnika prędkości: +, -, [, ]
        const SingleActivator(LogicalKeyboardKey.bracketRight):
            const ChangeRaceSpeedIntent(1),
        const SingleActivator(LogicalKeyboardKey.bracketLeft):
            const ChangeRaceSpeedIntent(-1),
        const SingleActivator(LogicalKeyboardKey.numpadAdd):
            const ChangeRaceSpeedIntent(1),
        const SingleActivator(LogicalKeyboardKey.numpadSubtract):
            const ChangeRaceSpeedIntent(-1),

        // Kolarze 1–8 (główny rząd + numpad)
        const SingleActivator(LogicalKeyboardKey.digit1):
            const SelectTeamRiderIntent(0),
        const SingleActivator(LogicalKeyboardKey.digit2):
            const SelectTeamRiderIntent(1),
        const SingleActivator(LogicalKeyboardKey.digit3):
            const SelectTeamRiderIntent(2),
        const SingleActivator(LogicalKeyboardKey.digit4):
            const SelectTeamRiderIntent(3),
        const SingleActivator(LogicalKeyboardKey.digit5):
            const SelectTeamRiderIntent(4),
        const SingleActivator(LogicalKeyboardKey.digit6):
            const SelectTeamRiderIntent(5),
        const SingleActivator(LogicalKeyboardKey.digit7):
            const SelectTeamRiderIntent(6),
        const SingleActivator(LogicalKeyboardKey.digit8):
            const SelectTeamRiderIntent(7),
        const SingleActivator(LogicalKeyboardKey.numpad1):
            const SelectTeamRiderIntent(0),
        const SingleActivator(LogicalKeyboardKey.numpad2):
            const SelectTeamRiderIntent(1),
        const SingleActivator(LogicalKeyboardKey.numpad3):
            const SelectTeamRiderIntent(2),
        const SingleActivator(LogicalKeyboardKey.numpad4):
            const SelectTeamRiderIntent(3),
        const SingleActivator(LogicalKeyboardKey.numpad5):
            const SelectTeamRiderIntent(4),
        const SingleActivator(LogicalKeyboardKey.numpad6):
            const SelectTeamRiderIntent(5),
        const SingleActivator(LogicalKeyboardKey.numpad7):
            const SelectTeamRiderIntent(6),
        const SingleActivator(LogicalKeyboardKey.numpad8):
            const SelectTeamRiderIntent(7),

        // Rozkazy taktyczne i żywienie
        const SingleActivator(LogicalKeyboardKey.keyA):
            const IssueRaceTacticalOrderIntent(TacticalOrder.attack),
        const SingleActivator(LogicalKeyboardKey.keyR):
            const IssueRaceTacticalOrderIntent(TacticalOrder.pullGroup),
        const SingleActivator(LogicalKeyboardKey.keyP):
            const IssueRaceTacticalOrderIntent(TacticalOrder.protectLeader),
        const SingleActivator(LogicalKeyboardKey.keyG):
            const ConsumeEnergyGelIntent(),
        const SingleActivator(LogicalKeyboardKey.keyB):
            const FetchTeamBidonsIntent(),

        // Kamera 3D, Aero Vision, HUD
        const SingleActivator(LogicalKeyboardKey.keyC):
            const CycleRaceCameraIntent(),
        const SingleActivator(LogicalKeyboardKey.keyV):
            const ToggleAeroVisionIntent(),
        const SingleActivator(LogicalKeyboardKey.tab):
            const ToggleHudPanelsIntent(),
      });
    }

    if (_managerShortcutsEnabled) {
      map.addAll({
        // Szybki zapis Ctrl+S (oraz Cmd+S na macOS)
        SingleActivator(
          LogicalKeyboardKey.keyS,
          control: !_isMacOs,
          meta: _isMacOs,
        ): const QuickSaveGameIntent(),
        // Dla wygody na macOS wspieramy także Ctrl+S
        if (_isMacOs)
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              const QuickSaveGameIntent(),

        // Przejście do kolejnego dnia: Enter lub Ctrl+Space (Cmd+Space na macOS)
        const SingleActivator(LogicalKeyboardKey.enter):
            const AdvanceCareerDayIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            const AdvanceCareerDayIntent(),
        const SingleActivator(
          LogicalKeyboardKey.space,
          control: true,
        ): const AdvanceCareerDayIntent(),
        if (_isMacOs)
          const SingleActivator(LogicalKeyboardKey.space, meta: true):
              const AdvanceCareerDayIntent(),
      });
    }

    return map;
  }

  Map<Type, Action<Intent>> _buildActionMap() {
    return {
      ToggleRacePauseIntent: CallbackAction<ToggleRacePauseIntent>(
        onInvoke: (_) {
          if (_isTypingInEditableText()) return null;
          _togglePause();
          return null;
        },
      ),
      ChangeRaceSpeedIntent: CallbackAction<ChangeRaceSpeedIntent>(
        onInvoke: (intent) {
          if (_isTypingInEditableText()) return null;
          _changeSimulationSpeed(intent.stepDelta);
          return null;
        },
      ),
      SelectTeamRiderIntent: CallbackAction<SelectTeamRiderIntent>(
        onInvoke: (intent) {
          if (_isTypingInEditableText()) return null;
          _selectRiderByIndex(intent.riderIndex);
          return null;
        },
      ),
      IssueRaceTacticalOrderIntent:
          CallbackAction<IssueRaceTacticalOrderIntent>(
        onInvoke: (intent) {
          if (_isTypingInEditableText()) return null;
          _issueTacticalOrder(intent.order);
          return null;
        },
      ),
      ConsumeEnergyGelIntent: CallbackAction<ConsumeEnergyGelIntent>(
        onInvoke: (_) {
          if (_isTypingInEditableText()) return null;
          _consumeGel();
          return null;
        },
      ),
      FetchTeamBidonsIntent: CallbackAction<FetchTeamBidonsIntent>(
        onInvoke: (_) {
          if (_isTypingInEditableText()) return null;
          _fetchBidons();
          return null;
        },
      ),
      CycleRaceCameraIntent: CallbackAction<CycleRaceCameraIntent>(
        onInvoke: (_) {
          if (_isTypingInEditableText()) return null;
          _cycleCameraMode();
          return null;
        },
      ),
      ToggleAeroVisionIntent: CallbackAction<ToggleAeroVisionIntent>(
        onInvoke: (_) {
          if (_isTypingInEditableText()) return null;
          _toggleAeroVision();
          return null;
        },
      ),
      ToggleHudPanelsIntent: CallbackAction<ToggleHudPanelsIntent>(
        onInvoke: (_) {
          if (_isTypingInEditableText()) return null;
          _toggleHudPanels();
          return null;
        },
      ),
      QuickSaveGameIntent: CallbackAction<QuickSaveGameIntent>(
        onInvoke: (_) {
          _quickSave();
          return null;
        },
      ),
      AdvanceCareerDayIntent: CallbackAction<AdvanceCareerDayIntent>(
        onInvoke: (_) {
          if (_isTypingInEditableText()) return null;
          _advanceDay();
          return null;
        },
      ),
      ToggleShortcutsCheatSheetIntent:
          CallbackAction<ToggleShortcutsCheatSheetIntent>(
        onInvoke: (_) {
          _toggleCheatSheet();
          return null;
        },
      ),
      CloseShortcutsCheatSheetIntent:
          CallbackAction<CloseShortcutsCheatSheetIntent>(
        onInvoke: (_) {
          _closeCheatSheet();
          return null;
        },
      ),
    };
  }

  // ==========================================================================
  // ACTION HANDLERS
  // ==========================================================================

  void _emitFeedback(String message) {
    widget.onShortcutTriggeredFeedback?.call(message);
  }

  void _togglePause() {
    if (widget.onTogglePause != null) {
      widget.onTogglePause!();
      _emitFeedback('Przełączono pauzę symulacji');
      return;
    }
    final notifier = ref.read(raceSimulationProvider.notifier);
    final wasPaused = ref.read(raceSimulationProvider).isPaused;
    notifier.togglePause();
    _emitFeedback(wasPaused ? 'Wznowiono symulację' : 'Symulacja wstrzymana');
  }

  void _changeSimulationSpeed(int delta) {
    final currentSpeed = ref.read(raceSimulationProvider).timeSpeed;
    final currentIndex = _speedSteps.indexOf(currentSpeed);
    final baseIndex = currentIndex >= 0 ? currentIndex : 0;
    final nextIndex = (baseIndex + delta).clamp(0, _speedSteps.length - 1);
    final nextSpeed = _speedSteps[nextIndex];

    if (widget.onSpeedChanged != null) {
      widget.onSpeedChanged!(nextSpeed);
    } else {
      ref.read(raceSimulationProvider.notifier).setSimulationSpeed(nextSpeed);
    }
    _emitFeedback('Prędkość symulacji: ${nextSpeed.label}');
  }

  void _selectRiderByIndex(int index) {
    if (widget.onSelectRiderBySlot != null) {
      widget.onSelectRiderBySlot!(index);
      _emitFeedback('Wybrano kolarza #${index + 1}');
      return;
    }

    final simState = ref.read(raceSimulationProvider);
    final playerRiders = simState.playerRidersPositions;
    if (index < 0 || index >= playerRiders.length) return;

    final targetRider = playerRiders[index];
    ref.read(raceSimulationProvider.notifier).selectRider(targetRider.riderId);
    _emitFeedback('Kamera na kolarza #${index + 1}: ${targetRider.riderName}');
  }

  String? _resolveSelectedRiderId({bool allowFallbackForCallback = false}) {
    final simState = ref.read(raceSimulationProvider);
    if (simState.selectedRiderId != null) return simState.selectedRiderId;
    if (simState.playerRidersPositions.isNotEmpty) {
      return simState.playerRidersPositions.first.riderId;
    }
    return allowFallbackForCallback ? 'selected_rider' : null;
  }

  void _issueTacticalOrder(TacticalOrder order) {
    final riderId = _resolveSelectedRiderId(
      allowFallbackForCallback: widget.onTacticalOrder != null,
    );
    if (riderId == null) return;

    if (widget.onTacticalOrder != null) {
      widget.onTacticalOrder!(riderId, order);
    } else {
      ref
          .read(raceSimulationProvider.notifier)
          .issueTacticalOrder(riderId, order);
    }
    _emitFeedback('Rozkaz: ${order.label}');
  }

  void _consumeGel() {
    final riderId = _resolveSelectedRiderId(
      allowFallbackForCallback: widget.onConsumeGel != null,
    );
    if (riderId == null) return;

    if (widget.onConsumeGel != null) {
      widget.onConsumeGel!(riderId);
    } else {
      ref.read(raceSimulationProvider.notifier).feedGelToRider(riderId);
    }
    _emitFeedback('Podano żel energetyczny');
  }

  void _fetchBidons() {
    final riderId = _resolveSelectedRiderId(
      allowFallbackForCallback: widget.onFetchBidons != null,
    );
    if (riderId == null) return;

    if (widget.onFetchBidons != null) {
      widget.onFetchBidons!(riderId);
    } else {
      final notifier = ref.read(raceSimulationProvider.notifier);
      notifier.issueTacticalOrder(riderId, TacticalOrder.fetchBidonsFromCar);
      notifier.sendDomestiqueForBidons(riderId);
    }
    _emitFeedback('Spłynięcie do wozu po bidony');
  }

  void _cycleCameraMode() {
    final currentIndex = _cameraCycle.indexOf(_currentCameraMode);
    final nextIndex = (currentIndex + 1) % _cameraCycle.length;
    setState(() {
      _currentCameraMode = _cameraCycle[nextIndex];
    });
    widget.onCameraModeChanged?.call(_currentCameraMode);
    _emitFeedback('Kamera: ${_currentCameraMode.shortLabel}');
  }

  void _toggleAeroVision() {
    setState(() {
      _isAeroVisionActive = !_isAeroVisionActive;
    });
    widget.onAeroVisionChanged?.call(_isAeroVisionActive);
    _emitFeedback(
      _isAeroVisionActive ? 'Aero Vision: WŁĄCZONY' : 'Aero Vision: WYŁĄCZONY',
    );
  }

  void _toggleHudPanels() {
    setState(() {
      _isHudVisible = !_isHudVisible;
    });
    widget.onHudVisibilityChanged?.call(_isHudVisible);
    _emitFeedback(_isHudVisible ? 'Panele HUD: Widoczne' : 'Panele HUD: Ukryte');
  }

  Future<void> _quickSave() async {
    if (widget.onQuickSave != null) {
      await widget.onQuickSave!();
      _emitFeedback('Szybki zapis gry ukończony');
      return;
    }

    final careerState = ref.read(careerProvider);
    if (!careerState.hasActiveSave) return;
    await ref.read(careerProvider.notifier).saveCurrentGame();
    _emitFeedback('Szybki zapis gry (Ctrl+S)');
  }

  void _advanceDay() {
    if (widget.onAdvanceDay != null) {
      widget.onAdvanceDay!();
      _emitFeedback('Przejście do następnego dnia');
      return;
    }

    final careerState = ref.read(careerProvider);
    if (!careerState.hasActiveSave) return;
    ref.read(careerProvider.notifier).advanceDay();
    _emitFeedback('Następny dzień kalendarza');
  }

  void _toggleCheatSheet() {
    setState(() {
      _isCheatSheetVisible = !_isCheatSheetVisible;
    });
  }

  void _closeCheatSheet() {
    if (!_isCheatSheetVisible) return;
    setState(() {
      _isCheatSheetVisible = false;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: _buildShortcutMap(),
      child: Actions(
        actions: _buildActionMap(),
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          child: Stack(
            children: [
              widget.child,
              if (_isCheatSheetVisible)
                Positioned.fill(
                  child: ShortcutsCheatSheetOverlay(
                    activeMode: widget.mode,
                    onClose: _closeCheatSheet,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// VISUAL OVERLAY: ShortcutsCheatSheetOverlay
// ============================================================================

/// Półprzezroczysty modal ściągi skrótów klawiszowych z kafelkami klawiszy 3D
/// (`#222630`) pogrupowanymi na sekcje, z pełną responsywnością i stanami
/// interakcji (`hover`, `active`, `focus`, `disabled`).
class ShortcutsCheatSheetOverlay extends StatefulWidget {
  final ShortcutContextMode activeMode;
  final VoidCallback onClose;

  const ShortcutsCheatSheetOverlay({
    super.key,
    required this.activeMode,
    required this.onClose,
  });

  @override
  State<ShortcutsCheatSheetOverlay> createState() =>
      _ShortcutsCheatSheetOverlayState();
}

class _ShortcutsCheatSheetOverlayState extends State<ShortcutsCheatSheetOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  ShortcutCategory? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool _isShortcutActiveInMode(ShortcutDefinition def) {
    if (widget.activeMode == ShortcutContextMode.both) return true;
    if (def.isRaceOnly && widget.activeMode != ShortcutContextMode.race3d) {
      return false;
    }
    if (def.isManagerOnly && widget.activeMode != ShortcutContextMode.manager) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            // Półprzezroczyste tło z rozmyciem
            Positioned.fill(
              child: GestureDetector(
                onTap: widget.onClose,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: AppColors.background.withValues(alpha: 0.78),
                  ),
                ),
              ),
            ),

            // Główny responsywny kontener modala
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    final isCompact = width < 640;
                    final isTablet = width >= 640 && width < 1100;

                    final modalWidth = isCompact
                        ? (width - 24).clamp(280.0, 420.0)
                        : isTablet
                            ? (width - 64).clamp(580.0, 920.0)
                            : (width * 0.76).clamp(840.0, 1140.0);
                    final modalMaxHeight = (height - (isCompact ? 32 : 64))
                        .clamp(320.0, 820.0);

                    return Container(
                      width: modalWidth,
                      constraints: BoxConstraints(maxHeight: modalMaxHeight),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderColor,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 36,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(isCompact),
                          const Divider(
                            color: AppTheme.borderColor,
                            height: 1,
                            thickness: 1,
                          ),
                          _buildFilterBar(isCompact),
                          Flexible(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.all(isCompact ? 14 : 22),
                              child: _buildSectionsGrid(isCompact, isTablet),
                            ),
                          ),
                          const Divider(
                            color: AppTheme.borderColor,
                            height: 1,
                            thickness: 1,
                          ),
                          _buildFooter(isCompact),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final modeBadgeLabel = switch (widget.activeMode) {
      ShortcutContextMode.race3d => 'TRYB WYŚCIGU 3D',
      ShortcutContextMode.manager => 'TRYB MENEDŻERA',
      ShortcutContextMode.both => 'PEŁNY ZAKRES',
    };

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: isCompact ? 14 : 18,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.keyboard_alt_rounded,
              color: AppColors.goldAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skróty Klawiszowe',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 17 : 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                const Text(
                  'Windows (.exe) • macOS (.dmg) • Klawiatury tabletowe',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isCompact) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primaryAccent.withValues(alpha: 0.55),
                ),
              ),
              child: Text(
                modeBadgeLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          _CheatSheetCloseButton(onTap: widget.onClose),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 24,
        vertical: 10,
      ),
      color: AppColors.background.withValues(alpha: 0.45),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _CategoryFilterChip(
              label: 'Wszystkie',
              icon: Icons.apps_rounded,
              accentColor: AppColors.goldAccent,
              isSelected: _selectedFilter == null,
              onTap: () => setState(() => _selectedFilter = null),
            ),
            const SizedBox(width: 8),
            ...ShortcutCategory.values.map((category) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _CategoryFilterChip(
                  label: category.title,
                  icon: category.icon,
                  accentColor: category.accentColor,
                  isSelected: _selectedFilter == category,
                  onTap: () => setState(() => _selectedFilter = category),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsGrid(bool isCompact, bool isTablet) {
    final categories = _selectedFilter != null
        ? [_selectedFilter!]
        : ShortcutCategory.values;

    final sectionWidgets = categories.map((category) {
      final items = KeyboardShortcutsCatalog.all
          .where((s) => s.category == category)
          .toList();
      return _ShortcutSectionCard(
        category: category,
        shortcuts: items,
        isShortcutActive: _isShortcutActiveInMode,
      );
    }).toList();

    if (isCompact || categories.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < sectionWidgets.length; i++) ...[
            sectionWidgets[i],
            if (i < sectionWidgets.length - 1) const SizedBox(height: 14),
          ],
        ],
      );
    }

    // Układ dwukolumnowy dla tabletu (1024x768) i desktopu (1600x900)
    final leftColumn = <Widget>[];
    final rightColumn = <Widget>[];
    for (int i = 0; i < sectionWidgets.length; i++) {
      if (i.isEven) {
        leftColumn.add(sectionWidgets[i]);
      } else {
        rightColumn.add(sectionWidgets[i]);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < leftColumn.length; i++) ...[
                leftColumn[i],
                if (i < leftColumn.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < rightColumn.length; i++) ...[
                rightColumn[i],
                if (i < rightColumn.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16 : 24,
        vertical: 12,
      ),
      child: Row(
        children: [
          const ShortcutKeycap(label: 'F1', compact: true),
          const SizedBox(width: 6),
          const Text(
            'lub',
            style: TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          const ShortcutKeycap(label: 'Esc', compact: true),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'aby zamknąć ściągę skrótów',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: widget.onClose,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(96, 38),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Zamknij',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sekcja grupująca powiązane skróty w karcie `BorderRadius.circular(16)`.
class _ShortcutSectionCard extends StatelessWidget {
  final ShortcutCategory category;
  final List<ShortcutDefinition> shortcuts;
  final bool Function(ShortcutDefinition) isShortcutActive;

  const _ShortcutSectionCard({
    required this.category,
    required this.shortcuts,
    required this.isShortcutActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                category.icon,
                color: category.accentColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.borderColor, height: 1),
          const SizedBox(height: 10),
          for (int i = 0; i < shortcuts.length; i++) ...[
            _ShortcutRowItem(
              definition: shortcuts[i],
              isActive: isShortcutActive(shortcuts[i]),
              accentColor: category.accentColor,
            ),
            if (i < shortcuts.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Pojedynczy wiersz skrótu z interaktywnym stanem hover/focus oraz kafelkami klawiszy 3D.
class _ShortcutRowItem extends StatefulWidget {
  final ShortcutDefinition definition;
  final bool isActive;
  final Color accentColor;

  const _ShortcutRowItem({
    required this.definition,
    required this.isActive,
    required this.accentColor,
  });

  @override
  State<_ShortcutRowItem> createState() => _ShortcutRowItemState();
}

class _ShortcutRowItemState extends State<_ShortcutRowItem> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    final bgColor = !active
        ? Colors.transparent
        : (_isHovered || _isFocused)
            ? AppColors.surfaceLight.withValues(alpha: 0.65)
            : AppColors.surface.withValues(alpha: 0.55);

    return FocusableActionDetector(
      enabled: active,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isFocused
                ? AppColors.goldAccent
                : (_isHovered && active)
                    ? AppTheme.borderColor
                    : Colors.transparent,
            width: 1.0,
          ),
        ),
        child: Opacity(
          opacity: active ? 1.0 : 0.45,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.definition.icon,
                size: 16,
                color: active ? widget.accentColor : AppColors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.definition.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.definition.description,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: _buildKeyCaps(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildKeyCaps() {
    final caps = widget.definition.keyCaps;
    final widgets = <Widget>[];
    for (int i = 0; i < caps.length; i++) {
      final text = caps[i];
      if (text == '–') {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              '–',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      } else {
        widgets.add(
          ShortcutKeycap(
            label: text,
            isHighlighted: _isHovered && widget.isActive,
            isDisabled: !widget.isActive,
          ),
        );
        if (caps.length == 2 &&
            i == 0 &&
            (caps.first == 'Ctrl' || caps.first == 'Cmd')) {
          widgets.add(
            const Text(
              '+',
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }
      }
    }
    return widgets;
  }
}

/// Elegancki kafelek klawisza (Keycap) w stylu `#222630` z trójwymiarowym obramowaniem.
class ShortcutKeycap extends StatefulWidget {
  final String label;
  final bool compact;
  final bool isHighlighted;
  final bool isDisabled;
  final VoidCallback? onTap;

  const ShortcutKeycap({
    super.key,
    required this.label,
    this.compact = false,
    this.isHighlighted = false,
    this.isDisabled = false,
    this.onTap,
  });

  @override
  State<ShortcutKeycap> createState() => _ShortcutKeycapState();
}

class _ShortcutKeycapState extends State<ShortcutKeycap> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final effectivePressed = _pressed && !widget.isDisabled;
    final effectiveHighlighted =
        (widget.isHighlighted || _hovered || _focused) && !widget.isDisabled;

    final topBorderColor = _focused
        ? AppColors.goldAccent
        : effectiveHighlighted
            ? AppColors.goldAccent.withValues(alpha: 0.7)
            : const Color(0xFF363C4D);

    final bottomEdgeHeight = effectivePressed ? 1.5 : 3.0;

    return FocusableActionDetector(
      enabled: widget.onTap != null && !widget.isDisabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: GestureDetector(
        onTapDown: widget.onTap != null && !widget.isDisabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.onTap != null && !widget.isDisabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              }
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, effectivePressed ? 1.5 : 0, 0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 7 : 10,
            vertical: widget.compact ? 3 : 5,
          ),
          constraints: BoxConstraints(minWidth: widget.compact ? 26 : 32),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight, // #222630
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: topBorderColor,
              width: 1.0,
            ),
            boxShadow: [
              // 3D efekt dolnej krawędzi klawisza
              BoxShadow(
                color: _focused
                    ? AppColors.goldAccent.withValues(alpha: 0.75)
                    : const Color(0xFF101319),
                blurRadius: 0,
                offset: Offset(0, bottomEdgeHeight),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: widget.isDisabled
                  ? AppColors.textSecondary
                  : effectiveHighlighted
                      ? AppColors.goldAccent
                      : AppColors.textPrimary,
              fontSize: widget.compact ? 11 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CategoryFilterChip> createState() => _CategoryFilterChipState();
}

class _CategoryFilterChipState extends State<_CategoryFilterChip> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? widget.accentColor.withValues(alpha: 0.18)
        : _hovered
            ? AppColors.surfaceLight
            : AppColors.surface;

    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.75)
            : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 15,
                color: widget.isSelected
                    ? widget.accentColor
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: widget.isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheatSheetCloseButton extends StatefulWidget {
  final VoidCallback onTap;

  const _CheatSheetCloseButton({required this.onTap});

  @override
  State<_CheatSheetCloseButton> createState() => _CheatSheetCloseButtonState();
}

class _CheatSheetCloseButtonState extends State<_CheatSheetCloseButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _pressed
                ? AppColors.primaryAccent.withValues(alpha: 0.35)
                : _hovered
                    ? AppColors.surfaceLight
                    : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : _hovered
                      ? AppColors.textSecondary
                      : AppTheme.borderColor,
              width: 1.0,
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 20,
            color: _hovered ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
