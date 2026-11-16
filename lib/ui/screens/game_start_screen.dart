import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/database/save_game_manager.dart';
import '../../state/career_controller.dart';

/// Ekran startowy i wyboru zapisu gry (GameStartScreen)
/// Główny punkt wejściowy do gry:
/// - Kontynuacja aktywnej kariery
/// - Kreator nowej kariery (NewCareerSetupScreen)
/// - Szybki start (Demo WorldTour 2026)
/// - Menedżer 5 slotów zapisu i auto-save
/// - Ustawienia grafiki i modowania (SettingsAndModScreen)
class GameStartScreen extends ConsumerStatefulWidget {
  const GameStartScreen({super.key});

  @override
  ConsumerState<GameStartScreen> createState() => _GameStartScreenState();
}

class _GameStartScreenState extends ConsumerState<GameStartScreen> {
  List<SaveSlotInfo> _slots = List.generate(6, (i) => SaveSlotInfo.empty(i));
  final bool _isLoadingSlots = false;
  bool _isPerformingAction = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _refreshSlots();
  }

  Future<void> _refreshSlots() async {
    try {
      final slots = await SaveGameManager.getAllSlots(includeAutoSave: true);
      if (mounted) {
        setState(() {
          _slots = slots;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleQuickStart() async {
    setState(() {
      _isPerformingAction = true;
      _statusMessage = 'Generowanie peletonu WorldTour 2026...';
    });

    final controller = ref.read(careerProvider.notifier);
    final success = await controller.startNewCareer(
      saveName: 'Kariera Aethelgard 2026',
      playerManagerName: 'Dyrektor Sportowy',
      playerTeamId: 'wt_aethel_veloce',
    );

    if (mounted) {
      setState(() {
        _isPerformingAction = false;
        _statusMessage = null;
      });

      if (success) {
        context.goToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.crimsonAlert,
            content: Text('Błąd podczas inicjalizacji szybkiego startu.'),
          ),
        );
      }
    }
  }

  Future<void> _handleLoadSlot(int slotNumber) async {
    setState(() {
      _isPerformingAction = true;
      _statusMessage = slotNumber == 0
          ? 'Wczytywanie automatycznego zapisu...'
          : 'Wczytywanie slotu #$slotNumber...';
    });

    final controller = ref.read(careerProvider.notifier);
    final bool success;
    if (slotNumber == 0) {
      success = await controller.loadAutoSave();
    } else {
      success = await controller.loadFromSlot(slotNumber);
    }

    if (mounted) {
      setState(() {
        _isPerformingAction = false;
        _statusMessage = null;
      });

      if (success) {
        context.goToDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.crimsonAlert,
            content: Text('Nie udało się wczytać zapisu ze slotu #$slotNumber.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final careerUiState = ref.watch(careerProvider);
    final currentSave = careerUiState.save;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Subtelne tło ze wzorem gradientu
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.4),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1A2234),
                    Color(0xFF0F121C),
                    Color(0xFF090B10),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),

                      if (currentSave != null) ...[
                        _buildActiveCareerCard(currentSave),
                        const SizedBox(height: 24),
                      ],

                      _buildActionGrid(currentSave != null),
                      const SizedBox(height: 28),

                      _buildSavesSection(),
                      const SizedBox(height: 24),

                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pasek ładowania / blokada podczas operacji I/O
          if (_isPerformingAction)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.goldAccent),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage ?? 'Przetwarzanie danych...',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.goldAccent, Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.goldAccent.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bike_rounded,
            size: 46,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'PRO PELOTON MANAGER',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: const Text(
            'UCI WorldTour & ProTeam Cycling Director Simulator • Sezon 2026',
            style: TextStyle(
              color: AppColors.goldAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCareerCard(dynamic save) {
    final teamName = save.playerTeam.name;
    final managerName = save.playerManagerName;
    final budgetStr = Formatters.formatCurrency(save.playerCashBalanceEur);
    final inGameDateStr =
        '${save.currentDate.day.toString().padLeft(2, '0')}.${save.currentDate.month.toString().padLeft(2, '0')}.${save.currentDate.year}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF172033),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_circle_filled_rounded, color: AppColors.goldAccent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AKTYWNA KARIERA W PAMIĘCI',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  teamName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dyrektor: $managerName • Dzień: $inGameDateStr • Budżet: $budgetStr',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => context.goToDashboard(),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            label: const Text('Kontynuuj'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid(bool hasActiveCareer) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        final children = [
          _buildActionCard(
            title: 'Nowa Kariera',
            subtitle: 'Wybierz zespół WorldTour lub stwórz własną stajnię od zera',
            icon: Icons.add_circle_outline_rounded,
            accentColor: AppColors.primaryAccent,
            onTap: () => context.goToNewCareer(),
            isHighlight: !hasActiveCareer,
          ),
          _buildActionCard(
            title: 'Szybki Wyścig 3D',
            subtitle: 'Laboratorium Taktyczne Sandbox • Wyścig 3D w 10 sekund',
            icon: Icons.view_in_ar_rounded,
            accentColor: AppColors.accentBlue,
            onTap: () => context.goToQuickRaceSandbox(),
            isHighlight: false,
          ),
          _buildActionCard(
            title: 'Szybki Start 2026',
            subtitle: 'Błyskawiczne rozpoczęcie sezonu z zespołem Aethelgard Veloce',
            icon: Icons.bolt_rounded,
            accentColor: AppColors.goldAccent,
            onTap: _handleQuickStart,
            isHighlight: false,
          ),
          _buildActionCard(
            title: 'Ustawienia & Mody',
            subtitle: 'Jakość 3D, FPS, edytor bazy danych oraz import pakietów JSON',
            icon: Icons.tune_rounded,
            accentColor: const Color(0xFF00E5FF),
            onTap: () => context.goToSettings(),
            isHighlight: false,
          ),
        ];

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children
                .map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: w)))
                .toList(),
          );
        } else {
          return Column(
            children: children
                .map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    required bool isHighlight,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFF1E283C) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isHighlight ? accentColor : AppTheme.borderColor,
            width: isHighlight ? 1.5 : 1.0,
          ),
          boxShadow: isHighlight
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.15),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(Icons.save_rounded, color: AppColors.goldAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Menedżer Zapisów Gry (Sloty 1-5 & Auto-Save)',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _refreshSlots,
                icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                tooltip: 'Odśwież listę zapisów',
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Wybierz istniejący zapis, aby wznowić karierę lub rozpocznij nową grę w wybranym slocie.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
          ),
          const SizedBox(height: 16),

          if (_isLoadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(color: AppColors.goldAccent),
              ),
            )
          else
            ...List.generate(6, (index) {
              // 0 to auto-save, 1..5 to sloty
              final slotNumber = index == 0 ? 0 : index;
              final slotInfo = _slots.firstWhere(
                (s) => s.slotNumber == slotNumber,
                orElse: () => SaveSlotInfo.empty(slotNumber),
              );

              return _buildSaveSlotRow(slotInfo);
            }),
        ],
      ),
    );
  }

  Widget _buildSaveSlotRow(SaveSlotInfo slot) {
    final bool isAutoSave = slot.slotNumber == 0;
    final bool isEmpty = !slot.isOccupied;

    final String slotLabel = isAutoSave ? 'Auto-Save' : 'Slot #${slot.slotNumber}';
    final Color slotColor = isAutoSave ? const Color(0xFF00E5FF) : AppColors.goldAccent;

    final teamName = slot.playerTeamName ?? 'Brak drużyny';
    final saveName = slot.saveName ?? 'Zapis gry';
    final inGameDate = slot.currentDate != null
        ? '${slot.currentDate!.day.toString().padLeft(2, '0')}.${slot.currentDate!.month.toString().padLeft(2, '0')}.${slot.currentDate!.year}'
        : '-';
    final realTimestamp = slot.lastSavedAt != null
        ? '${slot.lastSavedAt!.day.toString().padLeft(2, '0')}.${slot.lastSavedAt!.month.toString().padLeft(2, '0')} ${slot.lastSavedAt!.hour.toString().padLeft(2, '0')}:${slot.lastSavedAt!.minute.toString().padLeft(2, '0')}'
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEmpty ? const Color(0xFF11141E) : const Color(0xFF171C28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEmpty ? Colors.white.withValues(alpha: 0.04) : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: slotColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: slotColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              slotLabel,
              style: TextStyle(
                color: slotColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: isEmpty
                ? const Text(
                    'Pusty slot zapisu',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$saveName ($teamName)',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dzień w grze: $inGameDate • Zapisano: $realTimestamp',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
          ),

          if (!isEmpty) ...[
            ElevatedButton(
              onPressed: () => _handleLoadSlot(slot.slotNumber),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Wczytaj', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ],

          if (!isAutoSave)
            OutlinedButton(
              onPressed: () => context.goToNewCareer(initialSlot: slot.slotNumber),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(isEmpty ? 'Nowa gra' : 'Nadpisz', style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Wskazówka: Dystrybucja sił W\' i kadencja na czasówkach decydują o sekundach w klasyfikacji generalnej.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ),
        SizedBox(width: 12),
        Text(
          'v1.0.0 Pro Edition',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
