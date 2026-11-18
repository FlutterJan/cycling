import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../engine/peloton/rider_race_state.dart';

/// Kategoria szybkich komend głosowych/tekstowych radia wyścigowego.
enum VoiceCommandCategory {
  all,
  tactical,
  nutrition,
  formation,
  radio;

  /// Czytelna etykieta kategorii wyświetlana w filtrach palety.
  String get label {
    switch (this) {
      case VoiceCommandCategory.all:
        return 'Wszystkie';
      case VoiceCommandCategory.tactical:
        return 'Taktyka';
      case VoiceCommandCategory.nutrition:
        return 'Żywienie';
      case VoiceCommandCategory.formation:
        return 'Formacja';
      case VoiceCommandCategory.radio:
        return 'Radio DS';
    }
  }
}

/// Aktualny stan nasłuchiwania i przetwarzania komendy głosowej radia wyścigowego.
enum VoiceRadioListeningMode {
  idle,
  listening,
  processing,
  confirmed,
  error,
}

/// Reprezentacja kolarza dostępnego jako cel komendy głosowej/tekstowej.
class VoiceCommandTargetRider {
  final String riderId;
  final String name;
  final String roleLabel;
  final int bibNumber;
  final bool isAvailable;
  final String? unavailableReason;

  const VoiceCommandTargetRider({
    required this.riderId,
    required this.name,
    required this.roleLabel,
    required this.bibNumber,
    this.isAvailable = true,
    this.unavailableReason,
  });
}

/// Pojedyncza szybka komenda głosowa lub tekstowa dostępna w palecie `Alt+Space`.
class VoiceQuickCommandItem {
  final String id;
  final String title;
  final String subtitle;
  final String phraseExample;
  final String shortcutHint;
  final VoiceCommandCategory category;
  final TacticalOrder? tacticalOrder;
  final int? targetIntensityPercent;
  final List<String> keywords;
  final IconData icon;
  final Color accentColor;
  final bool isEnabled;
  final String? disabledReason;

  const VoiceQuickCommandItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.phraseExample,
    required this.shortcutHint,
    required this.category,
    this.tacticalOrder,
    this.targetIntensityPercent,
    required this.keywords,
    required this.icon,
    required this.accentColor,
    this.isEnabled = true,
    this.disabledReason,
  });

  VoiceQuickCommandItem copyWith({
    bool? isEnabled,
    String? disabledReason,
  }) {
    return VoiceQuickCommandItem(
      id: id,
      title: title,
      subtitle: subtitle,
      phraseExample: phraseExample,
      shortcutHint: shortcutHint,
      category: category,
      tacticalOrder: tacticalOrder,
      targetIntensityPercent: targetIntensityPercent,
      keywords: keywords,
      icon: icon,
      accentColor: accentColor,
      isEnabled: isEnabled ?? this.isEnabled,
      disabledReason: disabledReason ?? this.disabledReason,
    );
  }
}

/// Wynik rozpoznania i wykonania komendy z palety radia wyścigowego.
class VoiceCommandExecutionPayload {
  final VoiceQuickCommandItem command;
  final VoiceCommandTargetRider? targetRider;
  final String rawTranscript;
  final double confidence;
  final DateTime executedAt;

  const VoiceCommandExecutionPayload({
    required this.command,
    required this.targetRider,
    required this.rawTranscript,
    required this.confidence,
    required this.executedAt,
  });
}

/// Wynik dopasowania pojedynczej komendy przez parser fraz głosowych/tekstowych.
class VoiceCommandMatchResult {
  final VoiceQuickCommandItem command;
  final VoiceCommandTargetRider? detectedRider;
  final double score;

  const VoiceCommandMatchResult({
    required this.command,
    required this.detectedRider,
    required this.score,
  });
}

/// Deterministyczny parser komend głosowych i tekstowych radia wyścigowego (PL/EN).
class VoiceCommandParser {
  VoiceCommandParser._();

  static const Map<String, String> _diacriticMap = {
    'ą': 'a',
    'ć': 'c',
    'ę': 'e',
    'ł': 'l',
    'ń': 'n',
    'ó': 'o',
    'ś': 's',
    'ź': 'z',
    'ż': 'z',
  };

  /// Normalizuje tekst do postaci bez polskich znaków i zbędnych spacji.
  static String normalize(String input) {
    final lower = input.trim().toLowerCase();
    final buffer = StringBuffer();
    for (int i = 0; i < lower.length; i++) {
      final ch = lower[i];
      buffer.write(_diacriticMap[ch] ?? ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Wyszukuje kolarza po numerze startowym (`#12`) lub nazwisku w treści komendy.
  static VoiceCommandTargetRider? detectTargetRider(
    String query,
    List<VoiceCommandTargetRider> riders,
  ) {
    final normalized = normalize(query);
    if (normalized.isEmpty || riders.isEmpty) return null;

    final bibMatch = RegExp(r'#(\d{1,3})').firstMatch(normalized);
    if (bibMatch != null) {
      final bib = int.tryParse(bibMatch.group(1) ?? '');
      if (bib != null) {
        for (final rider in riders) {
          if (rider.bibNumber == bib && rider.isAvailable) {
            return rider;
          }
        }
      }
    }

    for (final rider in riders) {
      if (!rider.isAvailable) continue;
      final parts = normalize(rider.name).split(' ');
      for (final part in parts) {
        if (part.length >= 3 && normalized.contains(part)) {
          return rider;
        }
      }
    }
    return null;
  }

  /// Filtruje i sortuje komendy według dopasowania tekstowego i kategorii.
  static List<VoiceCommandMatchResult> filterAndRank({
    required String query,
    required VoiceCommandCategory category,
    required List<VoiceQuickCommandItem> commands,
    required List<VoiceCommandTargetRider> riders,
  }) {
    final normalizedQuery = normalize(query);
    final detectedRider = detectTargetRider(query, riders);
    final queryTokens = normalizedQuery
        .split(' ')
        .where((t) => t.isNotEmpty && !t.startsWith('#'))
        .toList();

    final List<VoiceCommandMatchResult> results = [];

    for (final command in commands) {
      if (category != VoiceCommandCategory.all && command.category != category) {
        continue;
      }

      if (normalizedQuery.isEmpty) {
        results.add(
          VoiceCommandMatchResult(
            command: command,
            detectedRider: detectedRider,
            score: command.isEnabled ? 1.0 : 0.4,
          ),
        );
        continue;
      }

      final titleNorm = normalize(command.title);
      final subtitleNorm = normalize(command.subtitle);
      final phraseNorm = normalize(command.phraseExample);
      final keywordsNorm = command.keywords.map(normalize).toList();

      double score = 0.0;
      if (titleNorm.contains(normalizedQuery)) {
        score += 0.95;
      } else if (phraseNorm.contains(normalizedQuery)) {
        score += 0.85;
      } else if (subtitleNorm.contains(normalizedQuery)) {
        score += 0.65;
      }

      int matchedTokens = 0;
      for (final token in queryTokens) {
        final inTitle = titleNorm.contains(token);
        final inKeywords = keywordsNorm.any((kw) => kw.contains(token) || token.contains(kw));
        final inPhrase = phraseNorm.contains(token);
        if (inTitle || inKeywords || inPhrase) {
          matchedTokens++;
          score += inTitle ? 0.35 : (inKeywords ? 0.30 : 0.20);
        }
      }

      if (score > 0.0 || (queryTokens.isEmpty && detectedRider != null)) {
        final clamped = (score == 0.0 ? 0.55 : score).clamp(0.0, 1.0);
        if (matchedTokens > 0 || score >= 0.45 || queryTokens.isEmpty) {
          results.add(
            VoiceCommandMatchResult(
              command: command,
              detectedRider: detectedRider,
              score: clamped,
            ),
          );
        }
      }
    }

    results.sort((a, b) {
      if (a.command.isEnabled != b.command.isEnabled) {
        return a.command.isEnabled ? -1 : 1;
      }
      return b.score.compareTo(a.score);
    });

    return results;
  }
}

/// Domyślny katalog produkcyjny szybkich komend radia wyścigowego.
class VoiceQuickCommandCatalog {
  VoiceQuickCommandCatalog._();

  static const List<VoiceQuickCommandItem> defaultCommands = [
    VoiceQuickCommandItem(
      id: 'cmd_attack_now',
      title: 'Atakuj teraz!',
      subtitle: 'Natychmiastowy skok beztlenowy z grupy (Z6/Z7)',
      phraseExample: '"Atakuj teraz na podjeździe"',
      shortcutHint: '1',
      category: VoiceCommandCategory.tactical,
      tacticalOrder: TacticalOrder.attack,
      targetIntensityPercent: 125,
      keywords: ['atak', 'attack', 'skok', 'odjazd', 'gaz', 'watt bomb'],
      icon: Icons.bolt_rounded,
      accentColor: AppColors.powerZone6,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_protect_leader',
      title: 'Chroń lidera GC',
      subtitle: 'Osłona przed wiatrem i utrzymanie czołowej pozycji',
      phraseExample: '"Chroń lidera przed wiatrem"',
      shortcutHint: '2',
      category: VoiceCommandCategory.tactical,
      tacticalOrder: TacticalOrder.protectLeader,
      targetIntensityPercent: 85,
      keywords: ['chron', 'lider', 'protect', 'leader', 'oslona', 'pomoc'],
      icon: Icons.shield_rounded,
      accentColor: AppColors.goldAccent,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_pull_group',
      title: 'Dawaj zmiany na czele (90% FTP)',
      subtitle: 'Kontrola tempa peletonu lub redukcja straty do ucieczki',
      phraseExample: '"Dawaj mocne zmiany 90 procent"',
      shortcutHint: '3',
      category: VoiceCommandCategory.tactical,
      tacticalOrder: TacticalOrder.pullGroup,
      targetIntensityPercent: 90,
      keywords: ['zmiany', 'pull', 'tempo', 'czolo', 'pogon', 'chase', '90'],
      icon: Icons.speed_rounded,
      accentColor: AppColors.accentBlue,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_follow_wheels',
      title: 'Pilnuj koła rywala',
      subtitle: 'Automatyczne kasowanie ataków najgroźniejszych faworytów',
      phraseExample: '"Pilnuj koła i sklejaj ataki"',
      shortcutHint: '4',
      category: VoiceCommandCategory.tactical,
      tacticalOrder: TacticalOrder.followWheels,
      targetIntensityPercent: 95,
      keywords: ['kolo', 'wheel', 'follow', 'sklej', 'pilnuj', 'mark'],
      icon: Icons.track_changes_rounded,
      accentColor: AppColors.cyanAccent,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_fetch_bidons',
      title: 'Zjedź po bidony do wozu',
      subtitle: 'Zjazd pomocnika po wodę i żele dla całego zespołu',
      phraseExample: '"Zjedź do wozu po bidony"',
      shortcutHint: '5',
      category: VoiceCommandCategory.nutrition,
      tacticalOrder: TacticalOrder.fetchBidonsFromCar,
      targetIntensityPercent: 68,
      keywords: ['bidon', 'woda', 'woz', 'fetch', 'bottle', 'picie', 'car'],
      icon: Icons.local_drink_rounded,
      accentColor: AppColors.statusSuccess,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_gel_intake',
      title: 'Przyjmij żel energetyczny (40g CHO)',
      subtitle: 'Natychmiastowe uzupełnienie glikogenu przed finałem',
      phraseExample: '"Weź żel przed ostatnią górką"',
      shortcutHint: '6',
      category: VoiceCommandCategory.nutrition,
      targetIntensityPercent: 75,
      keywords: ['zel', 'gel', 'jedzenie', 'glikogen', 'energia', 'baton', 'food'],
      icon: Icons.battery_charging_full_rounded,
      accentColor: AppColors.amberWarning,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_save_energy',
      title: 'Oszczędzaj siły w peletonie',
      subtitle: 'Głębokie schowanie w tunelu aerodynamicznym (Z1/Z2)',
      phraseExample: '"Schowaj się i oszczędzaj energię"',
      shortcutHint: '7',
      category: VoiceCommandCategory.formation,
      tacticalOrder: TacticalOrder.saveEnergy,
      targetIntensityPercent: 60,
      keywords: ['oszczedzaj', 'save', 'energy', 'schowaj', 'regeneracja', 'sit'],
      icon: Icons.eco_rounded,
      accentColor: AppColors.powerZone3,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_echelon_formation',
      title: 'Formuj wachlarz pod wiatr',
      subtitle: 'Diagonalne ustawienie drużyny na rancie przy wietrze bocznym',
      phraseExample: '"Ustaw wachlarz po prawej stronie"',
      shortcutHint: '8',
      category: VoiceCommandCategory.formation,
      tacticalOrder: TacticalOrder.pullGroup,
      targetIntensityPercent: 92,
      keywords: ['wachlarz', 'echelon', 'wiatr', 'crosswind', 'rant', 'gutter'],
      icon: Icons.air_rounded,
      accentColor: AppColors.accentBlue,
    ),
    VoiceQuickCommandItem(
      id: 'cmd_radio_gap_check',
      title: 'Zapytaj Radio Tour o straty czasowe',
      subtitle: 'Szybki meldunek o przewadze ucieczki i sytuacji na trasie',
      phraseExample: '"Podaj aktualną stratę do czołówki"',
      shortcutHint: '9',
      category: VoiceCommandCategory.radio,
      keywords: ['radio', 'strata', 'gap', 'czas', 'meldunek', 'tour', 'info'],
      icon: Icons.radio_rounded,
      accentColor: AppColors.primaryAccent,
    ),
  ];

  static const List<VoiceCommandTargetRider> defaultRiders = [
    VoiceCommandTargetRider(
      riderId: 'rider_leader',
      name: 'M. Kowalski',
      roleLabel: 'Lider GC',
      bibNumber: 11,
    ),
    VoiceCommandTargetRider(
      riderId: 'rider_climber',
      name: 'L. Moreau',
      roleLabel: 'Góral',
      bibNumber: 12,
    ),
    VoiceCommandTargetRider(
      riderId: 'rider_domestique',
      name: 'T. Nowak',
      roleLabel: 'Pomocnik',
      bibNumber: 14,
    ),
    VoiceCommandTargetRider(
      riderId: 'rider_sprinter',
      name: 'E. Rossi',
      roleLabel: 'Sprinter',
      bibNumber: 15,
    ),
  ];

  static const List<String> simulatedVoicePhrases = [
    'Chroń lidera przed wiatrem',
    '#12 atakuj na podjeździe',
    'Zjedź do wozu po bidony',
    'Dawaj mocne zmiany 90 procent',
    'Ustaw wachlarz na rancie',
  ];
}

/// Stan palety szybkich komend głosowych/tekstowych radia wyścigowego.
class VoiceCommandPaletteState {
  final bool isOpen;
  final String query;
  final VoiceCommandCategory selectedCategory;
  final String? selectedRiderId;
  final int highlightedIndex;
  final VoiceRadioListeningMode listeningMode;
  final String radioFrequencyMhz;
  final VoiceCommandExecutionPayload? lastExecuted;
  final List<VoiceCommandExecutionPayload> history;
  final String? statusMessage;

  const VoiceCommandPaletteState({
    this.isOpen = false,
    this.query = '',
    this.selectedCategory = VoiceCommandCategory.all,
    this.selectedRiderId,
    this.highlightedIndex = 0,
    this.listeningMode = VoiceRadioListeningMode.idle,
    this.radioFrequencyMhz = '154.650',
    this.lastExecuted,
    this.history = const [],
    this.statusMessage,
  });

  VoiceCommandPaletteState copyWith({
    bool? isOpen,
    String? query,
    VoiceCommandCategory? selectedCategory,
    String? selectedRiderId,
    bool clearSelectedRider = false,
    int? highlightedIndex,
    VoiceRadioListeningMode? listeningMode,
    String? radioFrequencyMhz,
    VoiceCommandExecutionPayload? lastExecuted,
    List<VoiceCommandExecutionPayload>? history,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return VoiceCommandPaletteState(
      isOpen: isOpen ?? this.isOpen,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedRiderId: clearSelectedRider ? null : (selectedRiderId ?? this.selectedRiderId),
      highlightedIndex: highlightedIndex ?? this.highlightedIndex,
      listeningMode: listeningMode ?? this.listeningMode,
      radioFrequencyMhz: radioFrequencyMhz ?? this.radioFrequencyMhz,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      history: history ?? this.history,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

/// Kontroler Riverpod zarządzający stanem palety szybkich komend radia (`Alt+Space`).
class VoiceCommandPaletteNotifier extends StateNotifier<VoiceCommandPaletteState> {
  VoiceCommandPaletteNotifier() : super(const VoiceCommandPaletteState());

  void openPalette() {
    state = state.copyWith(
      isOpen: true,
      highlightedIndex: 0,
      clearStatusMessage: true,
    );
  }

  void closePalette() {
    state = state.copyWith(
      isOpen: false,
      listeningMode: VoiceRadioListeningMode.idle,
    );
  }

  void togglePalette() {
    if (state.isOpen) {
      closePalette();
    } else {
      openPalette();
    }
  }

  void setQuery(String query) {
    state = state.copyWith(
      query: query,
      highlightedIndex: 0,
      listeningMode: VoiceRadioListeningMode.idle,
      clearStatusMessage: true,
    );
  }

  void setCategory(VoiceCommandCategory category) {
    state = state.copyWith(
      selectedCategory: category,
      highlightedIndex: 0,
    );
  }

  void selectRider(String? riderId) {
    if (riderId == null || riderId == state.selectedRiderId) {
      state = state.copyWith(clearSelectedRider: true);
    } else {
      state = state.copyWith(selectedRiderId: riderId);
    }
  }

  void setHighlightedIndex(int index, int maxLength) {
    if (maxLength <= 0) {
      state = state.copyWith(highlightedIndex: 0);
      return;
    }
    state = state.copyWith(
      highlightedIndex: index.clamp(0, maxLength - 1),
    );
  }

  void setListeningMode(VoiceRadioListeningMode mode, {String? statusMessage}) {
    state = state.copyWith(
      listeningMode: mode,
      statusMessage: statusMessage,
    );
  }

  VoiceCommandExecutionPayload? recordExecution({
    required VoiceQuickCommandItem command,
    required VoiceCommandTargetRider? targetRider,
    required double confidence,
    required String rawTranscript,
  }) {
    if (!command.isEnabled) {
      state = state.copyWith(
        listeningMode: VoiceRadioListeningMode.error,
        statusMessage: command.disabledReason ?? 'Komenda aktualnie niedostępna.',
      );
      return null;
    }

    final payload = VoiceCommandExecutionPayload(
      command: command,
      targetRider: targetRider,
      rawTranscript: rawTranscript,
      confidence: confidence,
      executedAt: DateTime.now(),
    );

    final updatedHistory = [payload, ...state.history];
    if (updatedHistory.length > 5) {
      updatedHistory.removeRange(5, updatedHistory.length);
    }

    final targetLabel = targetRider != null ? ' → #${targetRider.bibNumber} ${targetRider.name}' : ' → Cała drużyna';
    state = state.copyWith(
      lastExecuted: payload,
      history: updatedHistory,
      listeningMode: VoiceRadioListeningMode.confirmed,
      statusMessage: 'Nadano: ${command.title}$targetLabel',
    );
    return payload;
  }
}

/// Globalny provider palety szybkich komend radia wyścigowego.
final voiceCommandPaletteProvider =
    StateNotifierProvider<VoiceCommandPaletteNotifier, VoiceCommandPaletteState>(
  (ref) => VoiceCommandPaletteNotifier(),
);

/// Host skrótu klawiszowego `Alt+Space` otwierający paletę komend radia nad dowolnym widokiem.
class VoiceCommandQuickActionsShortcutHost extends StatefulWidget {
  final Widget child;
  final List<VoiceQuickCommandItem> commands;
  final List<VoiceCommandTargetRider> riders;
  final ValueChanged<VoiceCommandExecutionPayload>? onCommandExecuted;
  final bool enableShortcut;

  const VoiceCommandQuickActionsShortcutHost({
    super.key,
    required this.child,
    this.commands = VoiceQuickCommandCatalog.defaultCommands,
    this.riders = VoiceQuickCommandCatalog.defaultRiders,
    this.onCommandExecuted,
    this.enableShortcut = true,
  });

  @override
  State<VoiceCommandQuickActionsShortcutHost> createState() =>
      _VoiceCommandQuickActionsShortcutHostState();
}

class _VoiceCommandQuickActionsShortcutHostState
    extends State<VoiceCommandQuickActionsShortcutHost> {
  bool _isOpen = false;
  VoiceCommandExecutionPayload? _lastExecuted;

  void _togglePalette() {
    if (!widget.enableShortcut) return;
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _closePalette() {
    if (!_isOpen) return;
    setState(() {
      _isOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: widget.enableShortcut
          ? <ShortcutActivator, VoidCallback>{
              const SingleActivator(LogicalKeyboardKey.space, alt: true):
                  _togglePalette,
              if (_isOpen)
                const SingleActivator(LogicalKeyboardKey.escape): _closePalette,
            }
          : const <ShortcutActivator, VoidCallback>{},
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            widget.child,
            if (_isOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closePalette,
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.68),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(16),
                    child: GestureDetector(
                      onTap: () {},
                      child: VoiceCommandQuickActionsPalette(
                        commands: widget.commands,
                        riders: widget.riders,
                        initialLastExecuted: _lastExecuted,
                        onClose: _closePalette,
                        onCommandExecuted: (payload) {
                          setState(() {
                            _lastExecuted = payload;
                          });
                          widget.onCommandExecuted?.call(payload);
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Przycisk HUD wywołujący paletę komend radia (`Alt+Space`) z pełnymi stanami interakcji.
class VoiceCommandPaletteTriggerButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isListening;
  final bool isEnabled;
  final String label;

  const VoiceCommandPaletteTriggerButton({
    super.key,
    required this.onPressed,
    this.isListening = false,
    this.isEnabled = true,
    this.label = 'Radio DS',
  });

  @override
  State<VoiceCommandPaletteTriggerButton> createState() =>
      _VoiceCommandPaletteTriggerButtonState();
}

class _VoiceCommandPaletteTriggerButtonState
    extends State<VoiceCommandPaletteTriggerButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled && widget.onPressed != null;
    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.5)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isListening
                ? AppColors.crimsonAlert
                : _isHovered
                    ? AppColors.accentBlue
                    : AppTheme.borderColor;

    final Color bgColor = !enabled
        ? AppColors.surface.withValues(alpha: 0.5)
        : _isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.35)
            : _isHovered
                ? AppColors.surfaceLight
                : AppColors.surface;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
          onTap: enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.45,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 16,
                    color: widget.isListening
                        ? AppColors.crimsonAlert
                        : AppColors.goldAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor, width: 1.0),
                    ),
                    child: const Text(
                      'Alt+Space',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
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

/// Główna paleta szybkich komend głosowych i tekstowych radia wyścigowego (`Alt+Space`).
class VoiceCommandQuickActionsPalette extends StatefulWidget {
  final List<VoiceQuickCommandItem> commands;
  final List<VoiceCommandTargetRider> riders;
  final ValueChanged<VoiceCommandExecutionPayload>? onCommandExecuted;
  final VoidCallback? onClose;
  final VoiceCommandExecutionPayload? initialLastExecuted;
  final bool isVoiceInputEnabled;
  final String radioFrequencyMhz;

  const VoiceCommandQuickActionsPalette({
    super.key,
    this.commands = VoiceQuickCommandCatalog.defaultCommands,
    this.riders = VoiceQuickCommandCatalog.defaultRiders,
    this.onCommandExecuted,
    this.onClose,
    this.initialLastExecuted,
    this.isVoiceInputEnabled = true,
    this.radioFrequencyMhz = '154.650',
  });

  @override
  State<VoiceCommandQuickActionsPalette> createState() =>
      _VoiceCommandQuickActionsPaletteState();
}

class _VoiceCommandQuickActionsPaletteState
    extends State<VoiceCommandQuickActionsPalette>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late final AnimationController _waveController;

  Timer? _voiceSimulationTimer;
  int _simulatedPhraseIndex = 0;

  VoiceCommandCategory _selectedCategory = VoiceCommandCategory.all;
  String? _selectedRiderId;
  int _highlightedIndex = 0;
  VoiceRadioListeningMode _listeningMode = VoiceRadioListeningMode.idle;
  VoiceCommandExecutionPayload? _lastExecuted;
  String? _statusBannerText;

  @override
  void initState() {
    super.initState();
    _lastExecuted = widget.initialLastExecuted;
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _voiceSimulationTimer?.cancel();
    _waveController.dispose();
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    if (!mounted) return;
    setState(() {
      _highlightedIndex = 0;
      if (_listeningMode == VoiceRadioListeningMode.confirmed ||
          _listeningMode == VoiceRadioListeningMode.error) {
        _listeningMode = VoiceRadioListeningMode.idle;
      }
    });
  }

  List<VoiceCommandMatchResult> get _filteredMatches {
    return VoiceCommandParser.filterAndRank(
      query: _searchController.text,
      category: _selectedCategory,
      commands: widget.commands,
      riders: widget.riders,
    );
  }

  VoiceCommandTargetRider? _resolveTargetRider(
    VoiceCommandMatchResult? match,
  ) {
    if (_selectedRiderId != null) {
      for (final rider in widget.riders) {
        if (rider.riderId == _selectedRiderId && rider.isAvailable) {
          return rider;
        }
      }
    }
    return match?.detectedRider;
  }

  void _toggleVoiceListening() {
    if (!widget.isVoiceInputEnabled) return;

    if (_listeningMode == VoiceRadioListeningMode.listening) {
      _stopVoiceListening(applyTranscript: false);
      return;
    }

    _voiceSimulationTimer?.cancel();
    setState(() {
      _listeningMode = VoiceRadioListeningMode.listening;
      _statusBannerText = 'Nasłuchiwanie mikrofonu DS... Powiedz rozkaz lub wpisz tekst';
    });
    _waveController.repeat();

    _voiceSimulationTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _listeningMode != VoiceRadioListeningMode.listening) {
        return;
      }
      const phrases = VoiceQuickCommandCatalog.simulatedVoicePhrases;
      final phrase = phrases[_simulatedPhraseIndex % phrases.length];
      _simulatedPhraseIndex++;

      setState(() {
        _listeningMode = VoiceRadioListeningMode.processing;
        _searchController.text = phrase;
        _searchController.selection = TextSelection.collapsed(
          offset: phrase.length,
        );
        _statusBannerText = 'Rozpoznano transkrypcję głosową: "$phrase"';
      });
      _waveController.stop();
    });
  }

  void _stopVoiceListening({required bool applyTranscript}) {
    _voiceSimulationTimer?.cancel();
    _waveController.stop();
    setState(() {
      _listeningMode = VoiceRadioListeningMode.idle;
      if (!applyTranscript) {
        _statusBannerText = null;
      }
    });
  }

  void _moveHighlight(int delta) {
    final matches = _filteredMatches;
    if (matches.isEmpty) return;
    setState(() {
      _highlightedIndex = (_highlightedIndex + delta) % matches.length;
      if (_highlightedIndex < 0) {
        _highlightedIndex += matches.length;
      }
    });
  }

  void _executeMatch(VoiceCommandMatchResult match) {
    final command = match.command;
    if (!command.isEnabled) {
      setState(() {
        _listeningMode = VoiceRadioListeningMode.error;
        _statusBannerText =
            command.disabledReason ?? 'Komenda jest obecnie zablokowana.';
      });
      return;
    }

    _voiceSimulationTimer?.cancel();
    _waveController.stop();

    final rider = _resolveTargetRider(match);
    final rawText = _searchController.text.trim().isEmpty
        ? command.title
        : _searchController.text.trim();

    final payload = VoiceCommandExecutionPayload(
      command: command,
      targetRider: rider,
      rawTranscript: rawText,
      confidence: match.score,
      executedAt: DateTime.now(),
    );

    final targetSuffix = rider != null
        ? ' → #${rider.bibNumber} ${rider.name}'
        : ' → Cała drużyna';

    setState(() {
      _lastExecuted = payload;
      _listeningMode = VoiceRadioListeningMode.confirmed;
      _statusBannerText = 'Wysłano przez radio: ${command.title}$targetSuffix';
    });

    widget.onCommandExecuted?.call(payload);
  }

  void _executeHighlighted() {
    final matches = _filteredMatches;
    if (matches.isEmpty) return;
    final safeIndex = _highlightedIndex.clamp(0, matches.length - 1);
    _executeMatch(matches[safeIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final matches = _filteredMatches;
    final int safeHighlightIndex =
        matches.isEmpty ? 0 : _highlightedIndex.clamp(0, matches.length - 1);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          widget.onClose?.call();
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          _moveHighlight(1);
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          _moveHighlight(-1);
        },
        const SingleActivator(LogicalKeyboardKey.enter): _executeHighlighted,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxAvailableWidth =
              constraints.maxWidth.isFinite ? constraints.maxWidth : 1024;
          final double maxAvailableHeight =
              constraints.maxHeight.isFinite ? constraints.maxHeight : 768;

          final bool isMobile = maxAvailableWidth < 600;
          final bool isDesktop = maxAvailableWidth >= 1100;
          final double cardWidth = isMobile
              ? maxAvailableWidth
              : math.min(isDesktop ? 760.0 : 660.0, maxAvailableWidth);
          final double maxCardHeight =
              math.min(isMobile ? 640.0 : 620.0, maxAvailableHeight);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: cardWidth,
                maxHeight: maxCardHeight,
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _listeningMode == VoiceRadioListeningMode.listening
                          ? AppColors.crimsonAlert
                          : AppTheme.borderColor,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(isMobile: isMobile),
                      const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
                      _buildSearchAndVoiceBar(isMobile: isMobile),
                      _buildCategoryFilterRow(isMobile: isMobile),
                      _buildRiderSelectorRow(isMobile: isMobile),
                      const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
                      Flexible(
                        child: matches.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16,
                                  vertical: 10,
                                ),
                                shrinkWrap: true,
                                itemCount: matches.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final match = matches[index];
                                  return _VoiceCommandListTile(
                                    match: match,
                                    isHighlighted: index == safeHighlightIndex,
                                    isCompact: isMobile,
                                    selectedRider: _resolveTargetRider(match),
                                    onTap: () {
                                      setState(() => _highlightedIndex = index);
                                      _executeMatch(match);
                                    },
                                  );
                                },
                              ),
                      ),
                      if (_statusBannerText != null || _lastExecuted != null)
                        _buildStatusFeedbackBar(isMobile: isMobile),
                      if (!isMobile) _buildDesktopShortcutFooter(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 14 : 18,
        isMobile ? 12 : 14,
        isMobile ? 10 : 14,
        isMobile ? 10 : 12,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.6),
                width: 1.0,
              ),
            ),
            child: const Icon(
              Icons.headset_mic_rounded,
              size: 18,
              color: AppColors.goldAccent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paleta Komend Radia Wyścigowego',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _listeningMode == VoiceRadioListeningMode.listening
                            ? AppColors.crimsonAlert
                            : AppColors.statusSuccess,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Kanał DS ${widget.radioFrequencyMhz} MHz • Szybkie rozkazy',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          letterSpacing: -0.2,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
              ),
              child: const Text(
                'Alt + Space',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.goldAccent,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (widget.onClose != null)
            _PaletteIconButton(
              icon: Icons.close_rounded,
              tooltip: 'Zamknij (Esc)',
              onPressed: widget.onClose,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndVoiceBar({required bool isMobile}) {
    final bool isListening = _listeningMode == VoiceRadioListeningMode.listening;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16,
        12,
        isMobile ? 12 : 16,
        8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isListening
                      ? AppColors.crimsonAlert
                      : _searchFocusNode.hasFocus
                          ? AppColors.goldAccent
                          : AppTheme.borderColor,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: isListening
                        ? AppColors.crimsonAlert
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      cursorColor: AppColors.goldAccent,
                      decoration: const InputDecoration(
                        hintText: 'Wpisz komendę lub #numer (np. "#12 atakuj")...',
                        hintStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          letterSpacing: -0.2,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _executeHighlighted(),
                    ),
                  ),
                  if (isListening)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(28, 18),
                            painter: _VoiceWaveformPainter(
                              progress: _waveController.value,
                              color: AppColors.crimsonAlert,
                            ),
                          );
                        },
                      ),
                    ),
                  if (_searchController.text.isNotEmpty)
                    _PaletteIconButton(
                      icon: Icons.backspace_outlined,
                      tooltip: 'Wyczyść tekst',
                      size: 30,
                      iconSize: 15,
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.requestFocus();
                      },
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _VoiceMicToggleButton(
            isListening: isListening,
            isEnabled: widget.isVoiceInputEnabled,
            isCompact: isMobile,
            onPressed: _toggleVoiceListening,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterRow({required bool isMobile}) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
        itemCount: VoiceCommandCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = VoiceCommandCategory.values[index];
          final bool isSelected = _selectedCategory == category;
          return _InteractiveFilterChip(
            label: category.label,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedCategory = category;
                _highlightedIndex = 0;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildRiderSelectorRow({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
          itemCount: widget.riders.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            if (index == 0) {
              return _RiderTargetChip(
                label: 'Cała drużyna',
                isSelected: _selectedRiderId == null,
                isEnabled: true,
                onTap: () => setState(() => _selectedRiderId = null),
              );
            }
            final rider = widget.riders[index - 1];
            return _RiderTargetChip(
              label: '#${rider.bibNumber} ${rider.name}',
              roleHint: rider.roleLabel,
              isSelected: _selectedRiderId == rider.riderId,
              isEnabled: rider.isAvailable,
              disabledReason: rider.unavailableReason,
              onTap: rider.isAvailable
                  ? () {
                      setState(() {
                        _selectedRiderId =
                            _selectedRiderId == rider.riderId ? null : rider.riderId;
                      });
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.spatial_audio_off_rounded,
            size: 36,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 10),
          const Text(
            'Brak pasujących komend radiowych',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Spróbuj wpisać np. "atak", "bidony", "lider" lub wyczyść filtr kategorii.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),
          _InteractiveFilterChip(
            label: 'Wyczyść filtry',
            isSelected: true,
            onTap: () {
              setState(() {
                _selectedCategory = VoiceCommandCategory.all;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFeedbackBar({required bool isMobile}) {
    final bool isError = _listeningMode == VoiceRadioListeningMode.error;
    final bool isListening = _listeningMode == VoiceRadioListeningMode.listening;
    final Color statusColor = isError
        ? AppColors.crimsonAlert
        : isListening
            ? AppColors.amberWarning
            : AppColors.statusSuccess;

    final String text = _statusBannerText ??
        (_lastExecuted != null
            ? 'Ostatnia transmisja: ${_lastExecuted!.command.title}'
            : '');

    final int? confidencePct = _lastExecuted != null
        ? (_lastExecuted!.confidence * 100).round()
        : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.12),
        border: const Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
        borderRadius: isMobile
            ? const BorderRadius.vertical(bottom: Radius.circular(15))
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : isListening
                    ? Icons.graphic_eq_rounded
                    : Icons.check_circle_outline_rounded,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (confidencePct != null && !isListening && !isError)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor, width: 1.0),
              ),
              child: Text(
                'Pewność $confidencePct%',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: -0.2,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopShortcutFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppTheme.borderColor, width: 1.0)),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 14,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _FooterKeyHint(keys: '↑ ↓', label: 'Nawiguj'),
                _FooterKeyHint(keys: 'Enter', label: 'Wyślij rozkaz'),
                _FooterKeyHint(keys: 'Esc', label: 'Zamknij'),
              ],
            ),
          ),
          SizedBox(width: 8),
          Text(
            'Radio Stub v1.0',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceCommandListTile extends StatefulWidget {
  final VoiceCommandMatchResult match;
  final bool isHighlighted;
  final bool isCompact;
  final VoiceCommandTargetRider? selectedRider;
  final VoidCallback onTap;

  const _VoiceCommandListTile({
    required this.match,
    required this.isHighlighted,
    required this.isCompact,
    required this.selectedRider,
    required this.onTap,
  });

  @override
  State<_VoiceCommandListTile> createState() => _VoiceCommandListTileState();
}

class _VoiceCommandListTileState extends State<_VoiceCommandListTile> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final cmd = widget.match.command;
    final bool enabled = cmd.isEnabled;

    final Color bgColor = !enabled
        ? AppColors.background.withValues(alpha: 0.45)
        : _isPressed
            ? AppColors.primaryAccent.withValues(alpha: 0.25)
            : (widget.isHighlighted || _isHovered)
                ? AppColors.surfaceLight
                : AppColors.background.withValues(alpha: 0.72);

    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.45)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isHighlighted
                ? AppColors.goldAccent.withValues(alpha: 0.75)
                : _isHovered
                    ? AppColors.accentBlue.withValues(alpha: 0.65)
                    : AppTheme.borderColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCompact ? 10 : 12,
              vertical: widget.isCompact ? 9 : 10,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.48,
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cmd.accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: cmd.accentColor.withValues(alpha: 0.45),
                        width: 1.0,
                      ),
                    ),
                    child: Icon(
                      enabled ? cmd.icon : Icons.lock_outline_rounded,
                      size: 18,
                      color: enabled ? cmd.accentColor : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                cmd.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (widget.selectedRider != null && !widget.isCompact) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.goldAccent.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '#${widget.selectedRider!.bibNumber}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.goldAccent,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          enabled
                              ? (widget.isCompact ? cmd.subtitle : '${cmd.subtitle} • ${cmd.phraseExample}')
                              : (cmd.disabledReason ?? 'Komenda zablokowana'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!widget.isCompact && cmd.targetIntensityPercent != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderColor, width: 1.0),
                      ),
                      child: Text(
                        '${cmd.targetIntensityPercent}% FTP',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.borderColor, width: 1.0),
                    ),
                    child: Text(
                      cmd.shortcutHint,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.goldAccent,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
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

class _VoiceMicToggleButton extends StatefulWidget {
  final bool isListening;
  final bool isEnabled;
  final bool isCompact;
  final VoidCallback onPressed;

  const _VoiceMicToggleButton({
    required this.isListening,
    required this.isEnabled,
    required this.isCompact,
    required this.onPressed,
  });

  @override
  State<_VoiceMicToggleButton> createState() => _VoiceMicToggleButtonState();
}

class _VoiceMicToggleButtonState extends State<_VoiceMicToggleButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled;
    final Color bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isListening
            ? AppColors.crimsonAlert
            : _isPressed
                ? AppColors.primaryAccent
                : _isHovered
                    ? AppColors.primaryAccent.withValues(alpha: 0.85)
                    : AppColors.primaryAccent.withValues(alpha: 0.65);

    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isListening
                ? AppColors.crimsonAlert
                : AppColors.primaryAccent;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: Tooltip(
        message: enabled
            ? (widget.isListening ? 'Zatrzymaj mikrofon' : 'Mów do radia DS')
            : 'Mikrofon wyłączony',
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
            onTapCancel: enabled ? () => setState(() => _isPressed = false) : null,
            onTap: enabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 44,
              padding: EdgeInsets.symmetric(horizontal: widget.isCompact ? 12 : 14),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: _isFocused ? 1.5 : 1.0,
                ),
              ),
              child: Opacity(
                opacity: enabled ? 1.0 : 0.45,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                    if (!widget.isCompact) ...[
                      const SizedBox(width: 6),
                      Text(
                        widget.isListening ? 'Nasłuch...' : 'Mów',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveFilterChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InteractiveFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_InteractiveFilterChip> createState() => _InteractiveFilterChipState();
}

class _InteractiveFilterChipState extends State<_InteractiveFilterChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.isSelected
        ? AppColors.primaryAccent.withValues(alpha: 0.30)
        : _isHovered
            ? AppColors.surfaceLight
            : AppColors.background;

    final Color borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isSelected
            ? AppColors.primaryAccent
            : _isHovered
                ? AppColors.accentBlue.withValues(alpha: 0.6)
                : AppTheme.borderColor;

    return FocusableActionDetector(
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                color: widget.isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiderTargetChip extends StatefulWidget {
  final String label;
  final String? roleHint;
  final bool isSelected;
  final bool isEnabled;
  final String? disabledReason;
  final VoidCallback? onTap;

  const _RiderTargetChip({
    required this.label,
    this.roleHint,
    required this.isSelected,
    required this.isEnabled,
    this.disabledReason,
    this.onTap,
  });

  @override
  State<_RiderTargetChip> createState() => _RiderTargetChipState();
}

class _RiderTargetChipState extends State<_RiderTargetChip> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.isEnabled && widget.onTap != null;
    final Color bgColor = !enabled
        ? AppColors.background.withValues(alpha: 0.4)
        : widget.isSelected
            ? AppColors.goldAccent.withValues(alpha: 0.18)
            : _isHovered
                ? AppColors.surfaceLight
                : AppColors.background;

    final Color borderColor = !enabled
        ? AppTheme.borderColor.withValues(alpha: 0.4)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isSelected
                ? AppColors.goldAccent
                : AppTheme.borderColor;

    final chip = FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: _isFocused ? 1.5 : 1.0,
              ),
            ),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.42,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight:
                          widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: widget.isSelected
                          ? AppColors.goldAccent
                          : AppColors.textPrimary,
                      letterSpacing: -0.2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (widget.roleHint != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      widget.roleHint!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: AppColors.textSecondary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!enabled && widget.disabledReason != null) {
      return Tooltip(message: widget.disabledReason!, child: chip);
    }
    return chip;
  }
}

class _PaletteIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  const _PaletteIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 34,
    this.iconSize = 18,
  });

  @override
  State<_PaletteIconButton> createState() => _PaletteIconButtonState();
}

class _PaletteIconButtonState extends State<_PaletteIconButton> {
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (h) => setState(() => _isHovered = h),
      onShowFocusHighlight: (f) => setState(() => _isFocused = f),
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: _isHovered ? AppColors.surfaceLight : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isFocused ? AppColors.goldAccent : Colors.transparent,
                  width: 1.0,
                ),
              ),
              child: Icon(
                widget.icon,
                size: widget.iconSize,
                color: enabled ? AppColors.textSecondary : AppColors.textSecondary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterKeyHint extends StatelessWidget {
  final String keys;
  final String label;

  const _FooterKeyHint({required this.keys, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: AppTheme.borderColor, width: 1.0),
          ),
          child: Text(
            keys,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _VoiceWaveformPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _VoiceWaveformPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    const int barCount = 5;
    final double spacing = size.width / (barCount + 1);
    final double centerY = size.height / 2;

    for (int i = 0; i < barCount; i++) {
      final double phase = (progress * 2 * math.pi) + (i * 0.85);
      final double amplitude = 0.35 + 0.65 * ((math.sin(phase) + 1) / 2);
      final double halfHeight = (size.height * 0.44) * amplitude;
      final double x = spacing * (i + 1);
      canvas.drawLine(
        Offset(x, centerY - halfHeight),
        Offset(x, centerY + halfHeight),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
