import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/career/career_save.dart';
import '../../services/database/save_game_manager.dart';
import '../../state/career_controller.dart';

/// Tryb działania okna zarządzania zapisami gry.
enum SaveLoadModalMode {
  /// Pełne zarządzanie: zapis, wczytywanie, usuwanie oraz eksport/import `.json`.
  saveAndLoad,

  /// Wyłącznie wczytywanie, usuwanie i import (np. z ekranu tytułowego).
  loadOnly,

  /// Wyłącznie zapisywanie i eksport bieżącej kariery.
  saveOnly,
}

/// Rodzaj wykonanej akcji zwracanej po zamknięciu modala.
enum SaveLoadModalActionType {
  loaded,
  saved,
  deleted,
  imported,
  exported,
  cancelled,
}

/// Wynik operacji zwrócony przez [SaveLoadSlotsModal.show].
class SaveLoadModalResult {
  final SaveLoadModalActionType action;
  final int? slotNumber;
  final SaveSlotInfo? slotInfo;
  final String? exportedFilePath;

  const SaveLoadModalResult({
    required this.action,
    this.slotNumber,
    this.slotInfo,
    this.exportedFilePath,
  });
}

/// Rozszerzone metadane slotu zapisu zawierające pozycję UCI, czas gry i barwy herbu.
class SaveSlotEnrichedInfo {
  final SaveSlotInfo slot;
  final int? uciRank;
  final Duration? playTime;
  final String? secondaryColorHex;
  final String? teamShortCode;

  const SaveSlotEnrichedInfo({
    required this.slot,
    this.uciRank,
    this.playTime,
    this.secondaryColorHex,
    this.teamShortCode,
  });

  factory SaveSlotEnrichedInfo.fromSlotInfo(
    SaveSlotInfo slot, {
    CareerSave? save,
  }) {
    int? rank;
    Duration? playTime;
    String? secondaryHex;
    String? tla;

    if (save != null && slot.isOccupied) {
      final sortedTeams = [...save.teams]
        ..sort((a, b) => b.uciPointsSeason.compareTo(a.uciPointsSeason));
      final index = sortedTeams.indexWhere((t) => t.id == save.playerTeamId);
      if (index >= 0) {
        rank = index + 1;
      }

      final playerTeam = save.playerTeam;
      secondaryHex = playerTeam.secondaryJerseyColorHex;
      tla = _deriveTeamTla(playerTeam.name);

      final elapsed = save.lastSavedAt.difference(save.createdAt);
      if (!elapsed.isNegative) {
        playTime = elapsed;
      }
    } else if (slot.isOccupied && slot.playerTeamName != null) {
      tla = _deriveTeamTla(slot.playerTeamName!);
    }

    return SaveSlotEnrichedInfo(
      slot: slot,
      uciRank: rank,
      playTime: playTime,
      secondaryColorHex: secondaryHex,
      teamShortCode: tla,
    );
  }

  static String _deriveTeamTla(String teamName) {
    final words = teamName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'PPM';
    if (words.length == 1) {
      final w = words.first.toUpperCase();
      return w.length >= 3 ? w.substring(0, 3) : w.padRight(3, 'X');
    }
    if (words.length == 2) {
      final a = words[0].toUpperCase();
      final b = words[1].toUpperCase();
      return '${a.substring(0, math.min(2, a.length))}${b[0]}'.padRight(3, 'X');
    }
    return words
        .take(3)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}

/// Wektorowy malarz herbu drużyny kolarskiej (tarcza, pasy barw, monogram TLA i gwiazdka dywizji).
class TeamCrestPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final String teamTla;
  final bool isOccupied;
  final bool isWorldTour;
  final bool isAutoSave;

  const TeamCrestPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.teamTla,
    this.isOccupied = true,
    this.isWorldTour = false,
    this.isAutoSave = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final w = size.width;
    final h = size.height;

    final shieldPath = Path()
      ..moveTo(w * 0.50, h * 0.04)
      ..lineTo(w * 0.90, h * 0.16)
      ..lineTo(w * 0.86, h * 0.56)
      ..quadraticBezierTo(w * 0.80, h * 0.82, w * 0.50, h * 0.96)
      ..quadraticBezierTo(w * 0.20, h * 0.82, w * 0.14, h * 0.56)
      ..lineTo(w * 0.10, h * 0.16)
      ..close();

    if (!isOccupied) {
      final fillPaint = Paint()
        ..color = AppColors.surfaceLight.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawPath(shieldPath, fillPaint);

      final borderPaint = Paint()
        ..color = AppColors.cardBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      canvas.drawPath(shieldPath, borderPaint);

      final plusPaint = Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.65)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(w * 0.5, h * 0.38),
        Offset(w * 0.5, h * 0.62),
        plusPaint,
      );
      canvas.drawLine(
        Offset(w * 0.38, h * 0.50),
        Offset(w * 0.62, h * 0.50),
        plusPaint,
      );
      return;
    }

    canvas.save();
    canvas.clipPath(shieldPath);

    // Tło główne herbu
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = primaryColor,
    );

    // Ukośny pas drużynowy
    final stripePath = Path()
      ..moveTo(0, h * 0.62)
      ..lineTo(w, h * 0.24)
      ..lineTo(w, h * 0.48)
      ..lineTo(0, h * 0.86)
      ..close();
    canvas.drawPath(stripePath, Paint()..color = secondaryColor);

    // Złoty lub akcentowy detal szewronowy
    final accentPath = Path()
      ..moveTo(0, h * 0.56)
      ..lineTo(w, h * 0.18)
      ..lineTo(w, h * 0.24)
      ..lineTo(0, h * 0.62)
      ..close();
    canvas.drawPath(accentPath, Paint()..color = accentColor);

    // Subtelny połysk w górnej części tarczy
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.5));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.5), glossPaint);

    canvas.restore();

    // Obramowanie tarczy
    final borderColor = isAutoSave
        ? AppColors.cyanAccent
        : (isWorldTour ? AppColors.goldAccent : AppColors.textPrimary.withValues(alpha: 0.55));
    canvas.drawPath(
      shieldPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isAutoSave || isWorldTour ? 1.8 : 1.3,
    );

    // Monogram drużyny (TLA)
    final textPainter = TextPainter(
      text: TextSpan(
        text: teamTla,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: w * 0.24,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Color(0xCC000000),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (w - textPainter.width) * 0.5,
        h * 0.46 - textPainter.height * 0.5,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant TeamCrestPainter oldDelegate) {
    return oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.teamTla != teamTla ||
        oldDelegate.isOccupied != isOccupied ||
        oldDelegate.isWorldTour != isWorldTour ||
        oldDelegate.isAutoSave != isAutoSave;
  }
}

/// Okno zarządzania zapisami gry (`Auto-Save` + 5 slotów ręcznych) z podglądem herbu,
/// daty w karierze, budżetu, pozycji UCI, czasu gry oraz eksportem/importem `.json`.
class SaveLoadSlotsModal extends ConsumerStatefulWidget {
  final SaveLoadModalMode mode;
  final List<SaveSlotEnrichedInfo>? initialSlots;
  final int? activeSlotNumber;
  final CareerSave? activeCareerSave;
  final Future<List<SaveSlotEnrichedInfo>> Function()? slotsLoader;
  final Future<bool> Function(int slotNumber)? onLoadSlot;
  final Future<SaveSlotInfo?> Function(int slotNumber, String? customSaveName)? onSaveToSlot;
  final Future<bool> Function(int slotNumber)? onDeleteSlot;
  final Future<String> Function(int slotNumber)? onExportSlotJson;
  final Future<SaveSlotInfo> Function(String jsonContent, int targetSlot)? onImportSlotJson;
  final VoidCallback? onClose;

  const SaveLoadSlotsModal({
    super.key,
    this.mode = SaveLoadModalMode.saveAndLoad,
    this.initialSlots,
    this.activeSlotNumber,
    this.activeCareerSave,
    this.slotsLoader,
    this.onLoadSlot,
    this.onSaveToSlot,
    this.onDeleteSlot,
    this.onExportSlotJson,
    this.onImportSlotJson,
    this.onClose,
  });

  /// Wyświetla modal zarządzania zapisami gry nad bieżącym widokiem.
  static Future<SaveLoadModalResult?> show(
    BuildContext context, {
    SaveLoadModalMode mode = SaveLoadModalMode.saveAndLoad,
    List<SaveSlotEnrichedInfo>? initialSlots,
    int? activeSlotNumber,
    CareerSave? activeCareerSave,
    Future<List<SaveSlotEnrichedInfo>> Function()? slotsLoader,
    Future<bool> Function(int slotNumber)? onLoadSlot,
    Future<SaveSlotInfo?> Function(int slotNumber, String? customSaveName)? onSaveToSlot,
    Future<bool> Function(int slotNumber)? onDeleteSlot,
    Future<String> Function(int slotNumber)? onExportSlotJson,
    Future<SaveSlotInfo> Function(String jsonContent, int targetSlot)? onImportSlotJson,
  }) {
    return showGeneralDialog<SaveLoadModalResult>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Zamknij okno zapisów',
      barrierColor: Colors.black.withValues(alpha: 0.76),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) {
        return Center(
          child: SaveLoadSlotsModal(
            mode: mode,
            initialSlots: initialSlots,
            activeSlotNumber: activeSlotNumber,
            activeCareerSave: activeCareerSave,
            slotsLoader: slotsLoader,
            onLoadSlot: onLoadSlot,
            onSaveToSlot: onSaveToSlot,
            onDeleteSlot: onDeleteSlot,
            onExportSlotJson: onExportSlotJson,
            onImportSlotJson: onImportSlotJson,
          ),
        );
      },
    );
  }

  @override
  ConsumerState<SaveLoadSlotsModal> createState() => _SaveLoadSlotsModalState();
}

class _SaveLoadSlotsModalState extends ConsumerState<SaveLoadSlotsModal> {
  List<SaveSlotEnrichedInfo> _slots = const [];
  bool _isLoadingSlots = true;
  bool _isBusy = false;
  int? _confirmOverwriteSlot;
  int? _confirmDeleteSlot;
  String? _bannerMessage;
  bool _bannerIsError = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSlots != null) {
      _slots = _sortSlotsAutoSaveFirst(widget.initialSlots!);
      _isLoadingSlots = false;
    } else {
      _loadSlots();
    }
  }

  List<SaveSlotEnrichedInfo> _sortSlotsAutoSaveFirst(List<SaveSlotEnrichedInfo> raw) {
    final auto = raw.where((e) => e.slot.isAutoSave).toList();
    final manual = raw.where((e) => !e.slot.isAutoSave).toList()
      ..sort((a, b) => a.slot.slotNumber.compareTo(b.slot.slotNumber));
    return [...auto, ...manual];
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoadingSlots = true);
    try {
      if (widget.slotsLoader != null) {
        final loaded = await widget.slotsLoader!();
        if (!mounted) return;
        setState(() {
          _slots = _sortSlotsAutoSaveFirst(loaded);
          _isLoadingSlots = false;
        });
        return;
      }

      final rawSlots = await SaveGameManager.getAllSlots(includeAutoSave: true);
      final enriched = <SaveSlotEnrichedInfo>[];
      for (final slot in rawSlots) {
        CareerSave? loadedSave;
        if (slot.isOccupied) {
          try {
            loadedSave = slot.isAutoSave
                ? await SaveGameManager.loadAutoSave()
                : await SaveGameManager.loadFromSlot(slot.slotNumber);
          } catch (_) {
            loadedSave = null;
          }
        }
        enriched.add(SaveSlotEnrichedInfo.fromSlotInfo(slot, save: loadedSave));
      }

      if (!mounted) return;
      setState(() {
        _slots = _sortSlotsAutoSaveFirst(enriched);
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingSlots = false;
        _bannerMessage = 'Nie udało się odczytać slotów zapisu: $e';
        _bannerIsError = true;
      });
    }
  }

  void _setBanner(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _bannerMessage = message;
      _bannerIsError = isError;
    });
  }

  void _closeModal([SaveLoadModalResult? result]) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.of(context).maybePop(
      result ?? const SaveLoadModalResult(action: SaveLoadModalActionType.cancelled),
    );
  }

  Future<void> _handleLoadSlot(SaveSlotEnrichedInfo entry) async {
    if (_isBusy || !entry.slot.isOccupied) return;
    setState(() {
      _isBusy = true;
      _confirmOverwriteSlot = null;
      _confirmDeleteSlot = null;
    });

    try {
      bool ok;
      if (widget.onLoadSlot != null) {
        ok = await widget.onLoadSlot!(entry.slot.slotNumber);
      } else {
        final controller = ref.read(careerProvider.notifier);
        ok = entry.slot.isAutoSave
            ? await controller.loadAutoSave()
            : await controller.loadFromSlot(entry.slot.slotNumber);
      }

      if (!mounted) return;
      if (ok) {
        _closeModal(
          SaveLoadModalResult(
            action: SaveLoadModalActionType.loaded,
            slotNumber: entry.slot.slotNumber,
            slotInfo: entry.slot,
          ),
        );
      } else {
        setState(() => _isBusy = false);
        _setBanner(
          'Nie udało się wczytać zapisu ze slotu ${entry.slot.slotTitle}.',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setBanner('Błąd podczas wczytywania zapisu: $e', isError: true);
    }
  }

  Future<void> _handleSaveToSlot(SaveSlotEnrichedInfo entry) async {
    if (_isBusy || entry.slot.isAutoSave) return;

    if (entry.slot.isOccupied && _confirmOverwriteSlot != entry.slot.slotNumber) {
      setState(() {
        _confirmOverwriteSlot = entry.slot.slotNumber;
        _confirmDeleteSlot = null;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _confirmOverwriteSlot = null;
    });

    try {
      SaveSlotInfo? savedInfo;
      if (widget.onSaveToSlot != null) {
        savedInfo = await widget.onSaveToSlot!(entry.slot.slotNumber, null);
      } else {
        final controller = ref.read(careerProvider.notifier);
        savedInfo = await controller.saveToSlot(entry.slot.slotNumber);
      }

      if (!mounted) return;
      if (savedInfo != null) {
        await _loadSlots();
        if (!mounted) return;
        setState(() => _isBusy = false);
        _setBanner('Zapisano karierę w slocie ${entry.slot.slotNumber}.');
      } else {
        setState(() => _isBusy = false);
        _setBanner('Brak aktywnej kariery do zapisania.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setBanner('Błąd podczas zapisywania: $e', isError: true);
    }
  }

  Future<void> _handleDeleteSlot(SaveSlotEnrichedInfo entry) async {
    if (_isBusy || !entry.slot.isOccupied) return;

    if (_confirmDeleteSlot != entry.slot.slotNumber) {
      setState(() {
        _confirmDeleteSlot = entry.slot.slotNumber;
        _confirmOverwriteSlot = null;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _confirmDeleteSlot = null;
    });

    try {
      bool deleted;
      if (widget.onDeleteSlot != null) {
        deleted = await widget.onDeleteSlot!(entry.slot.slotNumber);
      } else if (entry.slot.isAutoSave) {
        deleted = await SaveGameManager.deleteAutoSave();
      } else {
        deleted = await SaveGameManager.deleteSlot(entry.slot.slotNumber);
      }

      if (!mounted) return;
      if (deleted) {
        await _loadSlots();
        if (!mounted) return;
        setState(() => _isBusy = false);
        _setBanner('Usunięto zapis ze slotu ${entry.slot.slotTitle}.');
      } else {
        setState(() => _isBusy = false);
        _setBanner('Nie udało się usunąć zapisu.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setBanner('Błąd podczas usuwania zapisu: $e', isError: true);
    }
  }

  Future<void> _openExportDialog(SaveSlotEnrichedInfo entry) async {
    if (_isBusy || !entry.slot.isOccupied) return;
    setState(() => _isBusy = true);

    String jsonPayload;
    String defaultExportPath = '';

    try {
      if (widget.onExportSlotJson != null) {
        jsonPayload = await widget.onExportSlotJson!(entry.slot.slotNumber);
        defaultExportPath = '${entry.slot.slotKey}_export.json';
      } else {
        jsonPayload = await SaveGameManager.exportSaveAsPortableJson(
          slotNumber: entry.slot.slotNumber,
        );
        try {
          final dir = await SaveGameManager.getSavesDirectory();
          final safeTeam = (entry.slot.playerTeamName ?? 'career')
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
          defaultExportPath =
              '${dir.path}${Platform.pathSeparator}exports${Platform.pathSeparator}${safeTeam}_${entry.slot.slotKey}.json';
        } catch (_) {
          defaultExportPath = '${entry.slot.slotKey}_export.json';
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setBanner('Nie udało się przygotować eksportu JSON: $e', isError: true);
      return;
    }

    if (!mounted) return;
    setState(() => _isBusy = false);

    final exportedPath = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => _ExportJsonDialog(
        slotTitle: entry.slot.slotTitle,
        teamName: entry.slot.playerTeamName ?? 'Kariera',
        jsonPayload: jsonPayload,
        defaultPath: defaultExportPath,
        slotNumber: entry.slot.slotNumber,
      ),
    );

    if (exportedPath != null && mounted) {
      _setBanner('Wyeksportowano zapis do: $exportedPath');
    }
  }

  Future<void> _openImportDialog() async {
    if (_isBusy) return;

    final importedResult = await showDialog<_ImportDialogResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (ctx) => _ImportJsonDialog(
        manualSlots: _slots.where((s) => !s.slot.isAutoSave).toList(),
      ),
    );

    if (importedResult == null || !mounted) return;

    setState(() => _isBusy = true);
    try {
      if (widget.onImportSlotJson != null) {
        await widget.onImportSlotJson!(
          importedResult.jsonContent,
          importedResult.targetSlotNumber,
        );
      } else {
        await SaveGameManager.importPortableSave(
          dataString: importedResult.jsonContent,
          targetSlotNumber: importedResult.targetSlotNumber,
        );
        await ref.read(careerProvider.notifier).refreshSlotsList();
      }

      await _loadSlots();
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setBanner(
        'Zaimportowano zapis do Slotu ${importedResult.targetSlotNumber}.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setBanner('Błąd importu pliku .json: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCareer = widget.activeCareerSave ?? ref.watch(careerProvider).save;
    final currentActiveSlot =
        widget.activeSlotNumber ?? ref.watch(careerProvider).activeSlotNumber;
    final canSaveCurrent = activeCareer != null && widget.mode != SaveLoadModalMode.loadOnly;
    final canLoad = widget.mode != SaveLoadModalMode.saveOnly;
    final canImport = widget.mode != SaveLoadModalMode.saveOnly;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => _closeModal(),
      },
      child: Focus(
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            final isCompact = maxWidth < 680;
            final modalWidth = isCompact ? maxWidth - 20 : math.min(1060.0, maxWidth - 40);
            final modalHeight = isCompact ? maxHeight - 28 : math.min(780.0, maxHeight - 40);

            return Material(
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: modalWidth,
                  height: modalHeight,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.65),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      children: [
                        // Złoty pasek akcentu u góry modala
                        Container(
                          height: 3,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryAccent,
                                AppColors.goldAccent,
                                AppColors.primaryAccent,
                              ],
                            ),
                          ),
                        ),
                        _buildHeader(
                          isCompact: isCompact,
                          activeCareer: activeCareer,
                          canImport: canImport,
                        ),
                        if (_bannerMessage != null)
                          _buildStatusBanner(
                            message: _bannerMessage!,
                            isError: _bannerIsError,
                          ),
                        Expanded(
                          child: _isLoadingSlots
                              ? _buildLoadingState()
                              : _buildSlotsBody(
                                  isCompact: isCompact,
                                  currentActiveSlot: currentActiveSlot,
                                  canSaveCurrent: canSaveCurrent,
                                  canLoad: canLoad,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({
    required bool isCompact,
    required CareerSave? activeCareer,
    required bool canImport,
  }) {
    final titleSection = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withValues(alpha: 0.6),
            ),
          ),
          child: const Icon(
            Icons.save_as_rounded,
            color: AppColors.goldAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ZARZĄDZANIE ZAPISAMI KARIERY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                activeCareer != null
                    ? 'Aktywna: ${activeCareer.playerTeam.name} • ${activeCareer.currentDate.toIso8601String().substring(0, 10)}'
                    : '5 slotów ręcznych + Auto-Save • Format przenośny .json',
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
        ),
      ],
    );

    final actionsSection = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canImport)
          _ModalActionButton(
            label: isCompact ? 'Import' : 'Importuj .json',
            icon: Icons.file_upload_outlined,
            accentColor: AppColors.accentBlue,
            enabled: !_isBusy,
            onPressed: _openImportDialog,
          ),
        const SizedBox(width: 8),
        _ModalIconCloseButton(
          enabled: !_isBusy,
          onPressed: () => _closeModal(),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 22,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: titleSection),
          const SizedBox(width: 12),
          actionsSection,
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required String message,
    required bool isError,
  }) {
    final toneColor = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: toneColor.withValues(alpha: 0.14),
        border: Border(
          bottom: BorderSide(color: toneColor.withValues(alpha: 0.45), width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: toneColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: toneColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _bannerMessage = null),
            icon: Icon(Icons.close, size: 16, color: toneColor),
            visualDensity: VisualDensity.compact,
            tooltip: 'Ukryj komunikat',
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.8,
              color: AppColors.goldAccent,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Odczytywanie slotów zapisu...',
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

  Widget _buildSlotsBody({
    required bool isCompact,
    required int? currentActiveSlot,
    required bool canSaveCurrent,
    required bool canLoad,
  }) {
    final autoSave = _slots.where((e) => e.slot.isAutoSave).toList();
    final manualSlots = _slots.where((e) => !e.slot.isAutoSave).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (autoSave.isNotEmpty) ...[
            _buildSectionLabel(
              icon: Icons.autorenew_rounded,
              title: 'AUTOMATYCZNY ZAPIS KARIERY',
              color: AppColors.cyanAccent,
            ),
            const SizedBox(height: 10),
            _SaveSlotCard(
              entry: autoSave.first,
              isActiveSlot: currentActiveSlot == 0,
              isCompact: isCompact,
              canLoad: canLoad,
              canSave: false,
              isBusy: _isBusy,
              confirmingOverwrite: false,
              confirmingDelete: _confirmDeleteSlot == 0,
              onLoad: () => _handleLoadSlot(autoSave.first),
              onSave: null,
              onDelete: () => _handleDeleteSlot(autoSave.first),
              onExport: () => _openExportDialog(autoSave.first),
            ),
            const SizedBox(height: 20),
          ],
          _buildSectionLabel(
            icon: Icons.inventory_2_outlined,
            title: 'SLOTY RĘCZNE (1 – 5)',
            color: AppColors.goldAccent,
          ),
          const SizedBox(height: 10),
          if (isCompact)
            Column(
              children: [
                for (int i = 0; i < manualSlots.length; i++) ...[
                  _SaveSlotCard(
                    entry: manualSlots[i],
                    isActiveSlot: currentActiveSlot == manualSlots[i].slot.slotNumber,
                    isCompact: true,
                    canLoad: canLoad,
                    canSave: canSaveCurrent,
                    isBusy: _isBusy,
                    confirmingOverwrite:
                        _confirmOverwriteSlot == manualSlots[i].slot.slotNumber,
                    confirmingDelete:
                        _confirmDeleteSlot == manualSlots[i].slot.slotNumber,
                    onLoad: () => _handleLoadSlot(manualSlots[i]),
                    onSave: () => _handleSaveToSlot(manualSlots[i]),
                    onDelete: () => _handleDeleteSlot(manualSlots[i]),
                    onExport: () => _openExportDialog(manualSlots[i]),
                  ),
                  if (i < manualSlots.length - 1) const SizedBox(height: 12),
                ],
              ],
            )
          else
            LayoutBuilder(
              builder: (context, gridConstraints) {
                const spacing = 14.0;
                final cardWidth = (gridConstraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: manualSlots.map((entry) {
                    return SizedBox(
                      width: cardWidth,
                      child: _SaveSlotCard(
                        entry: entry,
                        isActiveSlot: currentActiveSlot == entry.slot.slotNumber,
                        isCompact: false,
                        canLoad: canLoad,
                        canSave: canSaveCurrent,
                        isBusy: _isBusy,
                        confirmingOverwrite:
                            _confirmOverwriteSlot == entry.slot.slotNumber,
                        confirmingDelete:
                            _confirmDeleteSlot == entry.slot.slotNumber,
                        onLoad: () => _handleLoadSlot(entry),
                        onSave: () => _handleSaveToSlot(entry),
                        onDelete: () => _handleDeleteSlot(entry),
                        onExport: () => _openExportDialog(entry),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveSlotCard extends StatefulWidget {
  final SaveSlotEnrichedInfo entry;
  final bool isActiveSlot;
  final bool isCompact;
  final bool canLoad;
  final bool canSave;
  final bool isBusy;
  final bool confirmingOverwrite;
  final bool confirmingDelete;
  final VoidCallback onLoad;
  final VoidCallback? onSave;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const _SaveSlotCard({
    required this.entry,
    required this.isActiveSlot,
    required this.isCompact,
    required this.canLoad,
    required this.canSave,
    required this.isBusy,
    required this.confirmingOverwrite,
    required this.confirmingDelete,
    required this.onLoad,
    required this.onSave,
    required this.onDelete,
    required this.onExport,
  });

  @override
  State<_SaveSlotCard> createState() => _SaveSlotCardState();
}

class _SaveSlotCardState extends State<_SaveSlotCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    final clean = hex.trim().replaceFirst('#', '');
    final normalized = clean.length == 6 ? 'FF$clean' : clean;
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return fallback;
    return Color(value);
  }

  String _formatPlayTime(Duration? duration) {
    if (duration == null) return '-';
    final totalMinutes = duration.inMinutes;
    if (totalMinutes < 1) return '< 1 min';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours == 0) return '${mins}m';
    return '${hours.toString().padLeft(2, '0')}h ${mins.toString().padLeft(2, '0')}m';
  }

  String _formatBudget(int? cashEur) {
    if (cashEur == null) return '-';
    if (cashEur.abs() >= 1000000) {
      return Formatters.formatCompactCurrency(cashEur);
    }
    return Formatters.formatCurrency(cashEur);
  }

  String _formatUciPosition(SaveSlotEnrichedInfo entry) {
    final rank = entry.uciRank;
    final pts = entry.slot.uciPointsSeason;
    if (rank != null && pts != null) {
      return '#$rank • $pts pkt';
    }
    if (rank != null) {
      return '#$rank UCI';
    }
    if (pts != null) {
      return '$pts pkt UCI';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.entry.slot;
    final occupied = slot.isOccupied;
    final isAuto = slot.isAutoSave;

    final primaryTeamColor = _parseHexColor(
      slot.playerTeamJerseyPrimaryHex,
      isAuto ? AppColors.cyanAccent : AppColors.primaryAccent,
    );
    final secondaryTeamColor = _parseHexColor(
      widget.entry.secondaryColorHex,
      AppColors.surfaceLight,
    );

    final borderColor = _isFocused
        ? AppColors.goldAccent
        : widget.isActiveSlot
            ? AppColors.goldAccent.withValues(alpha: 0.78)
            : _isHovered
                ? (isAuto ? AppColors.cyanAccent.withValues(alpha: 0.65) : AppColors.primaryAccent.withValues(alpha: 0.85))
                : AppTheme.borderColor;

    final backgroundColor = _isHovered
        ? AppColors.surfaceLight
        : AppColors.surface;

    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.all(widget.isCompact ? 14 : 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: _isFocused || widget.isActiveSlot ? 1.4 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 48,
                    height: 54,
                    child: CustomPaint(
                      painter: TeamCrestPainter(
                        primaryColor: primaryTeamColor,
                        secondaryColor: secondaryTeamColor,
                        accentColor: isAuto ? AppColors.cyanAccent : AppColors.goldAccent,
                        teamTla: widget.entry.teamShortCode ?? 'PPM',
                        isOccupied: occupied,
                        isWorldTour: (slot.playerTeamDivision ?? '').contains('WT') ||
                            (slot.playerTeamDivision ?? '').contains('WORLD'),
                        isAutoSave: isAuto,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _SlotTagBadge(
                              label: isAuto ? 'AUTO-SAVE' : 'SLOT ${slot.slotNumber}',
                              color: isAuto ? AppColors.cyanAccent : AppColors.goldAccent,
                            ),
                            if (widget.isActiveSlot)
                              const _SlotTagBadge(
                                label: 'AKTYWNY',
                                color: AppColors.statusSuccess,
                              ),
                            if (occupied && slot.playerTeamDivision != null)
                              _SlotTagBadge(
                                label: slot.playerTeamDivision!,
                                color: AppColors.textSecondary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          occupied
                              ? (slot.saveName ?? 'Zapis kariery')
                              : 'Pusty slot zapisu',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: occupied
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          occupied
                              ? '${slot.playerTeamName ?? 'Drużyna'} • ${slot.playerManagerName ?? 'Menedżer'}'
                              : 'Gotowy na zapis nowej lub bieżącej kariery',
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
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (occupied) ...[
                _buildTelemetryStrip(slot),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Zapisano: ${slot.formattedLastSavedAt} • ${slot.formattedFileSize}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.65)),
                  ),
                  child: const Text(
                    'Brak zapisanych danych w tym slocie.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _buildActionsRow(occupied: occupied, isAuto: isAuto),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryStrip(SaveSlotInfo slot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          _TelemetryItem(
            icon: Icons.calendar_today_rounded,
            label: 'DATA',
            value: slot.formattedDate,
          ),
          _TelemetryItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'BUDŻET',
            value: _formatBudget(slot.cashBalanceEur),
          ),
          _TelemetryItem(
            icon: Icons.emoji_events_outlined,
            label: 'RANKING UCI',
            value: _formatUciPosition(widget.entry),
            valueColor: AppColors.goldAccent,
          ),
          _TelemetryItem(
            icon: Icons.timer_outlined,
            label: 'CZAS GRY',
            value: _formatPlayTime(widget.entry.playTime),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow({
    required bool occupied,
    required bool isAuto,
  }) {
    final disabled = widget.isBusy;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (widget.canLoad)
          _ModalActionButton(
            label: 'Wczytaj',
            icon: Icons.play_arrow_rounded,
            accentColor: AppColors.statusSuccess,
            enabled: occupied && !disabled,
            filled: occupied,
            onPressed: widget.onLoad,
          ),
        if (!isAuto && widget.onSave != null)
          _ModalActionButton(
            label: widget.confirmingOverwrite ? 'Potwierdź nadpisanie' : 'Zapisz',
            icon: Icons.save_outlined,
            accentColor: widget.confirmingOverwrite
                ? AppColors.amberWarning
                : AppColors.primaryAccent,
            enabled: widget.canSave && !disabled,
            filled: widget.confirmingOverwrite,
            onPressed: widget.onSave!,
          ),
        _ModalActionButton(
          label: 'Eksport .json',
          icon: Icons.file_download_outlined,
          accentColor: AppColors.accentBlue,
          enabled: occupied && !disabled,
          onPressed: widget.onExport,
        ),
        _ModalActionButton(
          label: widget.confirmingDelete ? 'Potwierdź usunięcie' : 'Usuń',
          icon: Icons.delete_outline_rounded,
          accentColor: AppColors.crimsonAlert,
          enabled: occupied && !disabled,
          filled: widget.confirmingDelete,
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}

class _SlotTagBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SlotTagBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: color,
        ),
      ),
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _TelemetryItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModalActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool enabled;
  final bool filled;
  final VoidCallback onPressed;

  const _ModalActionButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.enabled,
    this.filled = false,
    required this.onPressed,
  });

  @override
  State<_ModalActionButton> createState() => _ModalActionButtonState();
}

class _ModalActionButtonState extends State<_ModalActionButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    final bgColor = !enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.35)
        : widget.filled
            ? (_pressed
                ? widget.accentColor.withValues(alpha: 0.78)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.92)
                    : widget.accentColor.withValues(alpha: 0.85))
            : (_pressed
                ? widget.accentColor.withValues(alpha: 0.28)
                : _hovered
                    ? widget.accentColor.withValues(alpha: 0.20)
                    : widget.accentColor.withValues(alpha: 0.11));

    final borderColor = !enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.accentColor.withValues(alpha: _hovered ? 0.9 : 0.55);

    final fgColor = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : widget.filled
            ? Colors.white
            : widget.accentColor;

    return FocusableActionDetector(
      enabled: enabled,
      onShowFocusHighlight: (focused) => setState(() => _focused = focused),
      onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
      mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
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
              Icon(widget.icon, size: 15, color: fgColor),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fgColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModalIconCloseButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _ModalIconCloseButton({
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ModalIconCloseButton> createState() => _ModalIconCloseButtonState();
}

class _ModalIconCloseButtonState extends State<_ModalIconCloseButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      mouseCursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.crimsonAlert.withValues(alpha: 0.2)
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _focused
                  ? AppColors.goldAccent
                  : (_hovered ? AppColors.crimsonAlert : AppTheme.borderColor),
            ),
          ),
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: _hovered ? AppColors.crimsonAlert : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ExportJsonDialog extends StatefulWidget {
  final String slotTitle;
  final String teamName;
  final String jsonPayload;
  final String defaultPath;
  final int slotNumber;

  const _ExportJsonDialog({
    required this.slotTitle,
    required this.teamName,
    required this.jsonPayload,
    required this.defaultPath,
    required this.slotNumber,
  });

  @override
  State<_ExportJsonDialog> createState() => _ExportJsonDialogState();
}

class _ExportJsonDialogState extends State<_ExportJsonDialog> {
  late final TextEditingController _pathController;
  bool _isSaving = false;
  String? _statusText;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _pathController = TextEditingController(text: widget.defaultPath);
  }

  @override
  void dispose() {
    _pathController.dispose();
    super.dispose();
  }

  Future<void> _saveToFile() async {
    final targetPath = _pathController.text.trim();
    if (targetPath.isEmpty) {
      setState(() {
        _statusText = 'Podaj poprawną ścieżkę docelową pliku .json.';
        _isError = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusText = null;
    });

    try {
      final file = File(targetPath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsString(widget.jsonPayload, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _statusText = 'Nie udało się zapisać pliku: $e';
        _isError = true;
      });
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.jsonPayload));
    if (!mounted) return;
    setState(() {
      _statusText = 'Skopiowano zawartość zapisu .json do schowka.';
      _isError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final byteCount = utf8.encode(widget.jsonPayload).length;
    final sizeLabel = byteCount < 1024
        ? '$byteCount B'
        : '${(byteCount / 1024).toStringAsFixed(1)} KB';

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.file_download_outlined, color: AppColors.accentBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Eksport zapisu: ${widget.slotTitle}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.teamName} • Rozmiar pakietu: $sizeLabel • Suma kontrolna FNV-1a 64-bit',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pathController,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Ścieżka docelowa pliku .json',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.borderColor),
                  ),
                ),
              ),
              if (_statusText != null) ...[
                const SizedBox(height: 10),
                Text(
                  _statusText!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _isError ? AppColors.crimsonAlert : AppColors.statusSuccess,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ModalActionButton(
                    label: 'Anuluj',
                    icon: Icons.close,
                    accentColor: AppColors.textSecondary,
                    enabled: !_isSaving,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  _ModalActionButton(
                    label: 'Kopiuj JSON',
                    icon: Icons.copy_rounded,
                    accentColor: AppColors.goldAccent,
                    enabled: !_isSaving,
                    onPressed: _copyToClipboard,
                  ),
                  _ModalActionButton(
                    label: _isSaving ? 'Zapisywanie...' : 'Zapisz plik .json',
                    icon: Icons.save_alt_rounded,
                    accentColor: AppColors.accentBlue,
                    enabled: !_isSaving,
                    filled: true,
                    onPressed: _saveToFile,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportDialogResult {
  final String jsonContent;
  final int targetSlotNumber;

  const _ImportDialogResult({
    required this.jsonContent,
    required this.targetSlotNumber,
  });
}

class _ImportJsonDialog extends StatefulWidget {
  final List<SaveSlotEnrichedInfo> manualSlots;

  const _ImportJsonDialog({required this.manualSlots});

  @override
  State<_ImportJsonDialog> createState() => _ImportJsonDialogState();
}

class _ImportJsonDialogState extends State<_ImportJsonDialog> {
  final TextEditingController _pathController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  int _selectedTargetSlot = 1;
  bool _isPasteMode = false;
  SaveValidationResult? _validationResult;
  List<File> _discoveredFiles = const [];

  @override
  void initState() {
    super.initState();
    final firstEmpty = widget.manualSlots.where((s) => !s.slot.isOccupied).toList();
    if (firstEmpty.isNotEmpty) {
      _selectedTargetSlot = firstEmpty.first.slot.slotNumber;
    }
    _discoverExportedFiles();
  }

  @override
  void dispose() {
    _pathController.dispose();
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _discoverExportedFiles() async {
    try {
      final dir = await SaveGameManager.getSavesDirectory();
      final exportsDir = Directory('${dir.path}${Platform.pathSeparator}exports');
      final found = <File>[];
      if (await exportsDir.exists()) {
        for (final entity in exportsDir.listSync()) {
          if (entity is File && entity.path.toLowerCase().endsWith('.json')) {
            found.add(entity);
          }
        }
      }
      if (!mounted) return;
      setState(() => _discoveredFiles = found);
    } catch (_) {}
  }

  Future<void> _loadFromPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) return;
    try {
      final file = File(path);
      if (!await file.exists()) {
        setState(() {
          _validationResult = const SaveValidationResult(
            isValid: false,
            errorMessage: 'Nie znaleziono wskazanego pliku .json.',
          );
        });
        return;
      }
      final content = await file.readAsString();
      _jsonController.text = content;
      _validateJson(content);
    } catch (e) {
      setState(() {
        _validationResult = SaveValidationResult(
          isValid: false,
          errorMessage: 'Błąd odczytu pliku: $e',
        );
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.isNotEmpty) {
      _jsonController.text = text;
      _validateJson(text);
    }
  }

  void _validateJson(String raw) {
    if (raw.trim().isEmpty) {
      setState(() => _validationResult = null);
      return;
    }
    final result = SaveGameManager.validatePortableSave(raw);
    setState(() => _validationResult = result);
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _validationResult?.isValid ?? false;
    final slotMeta = _validationResult?.slotInfo;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.file_upload_outlined, color: AppColors.accentBlue),
                    SizedBox(width: 10),
                    Text(
                      'Import zapisu z pliku .json',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _ModalActionButton(
                      label: 'Z pliku .json',
                      icon: Icons.folder_open_rounded,
                      accentColor: AppColors.accentBlue,
                      enabled: true,
                      filled: !_isPasteMode,
                      onPressed: () => setState(() => _isPasteMode = false),
                    ),
                    const SizedBox(width: 8),
                    _ModalActionButton(
                      label: 'Wklej JSON',
                      icon: Icons.paste_rounded,
                      accentColor: AppColors.goldAccent,
                      enabled: true,
                      filled: _isPasteMode,
                      onPressed: () => setState(() => _isPasteMode = true),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!_isPasteMode) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pathController,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Ścieżka do pliku .json',
                            labelStyle: const TextStyle(color: AppColors.textSecondary),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.borderColor),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ModalActionButton(
                        label: 'Sprawdź',
                        icon: Icons.verified_outlined,
                        accentColor: AppColors.accentBlue,
                        enabled: true,
                        onPressed: _loadFromPath,
                      ),
                    ],
                  ),
                  if (_discoveredFiles.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Wykryte eksporty w folderze zapisów:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _discoveredFiles.take(5).map((file) {
                        final name = file.uri.pathSegments.last;
                        return _ModalActionButton(
                          label: name,
                          icon: Icons.description_outlined,
                          accentColor: AppColors.cyanAccent,
                          enabled: true,
                          onPressed: () {
                            _pathController.text = file.path;
                            _loadFromPath();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ] else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ModalActionButton(
                      label: 'Wklej ze schowka',
                      icon: Icons.content_paste_go_rounded,
                      accentColor: AppColors.goldAccent,
                      enabled: true,
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _jsonController,
                    maxLines: 5,
                    onChanged: _validateJson,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Wklej zawartość pliku .json (PPM_SAVE_V1 lub CareerSave)...',
                      hintStyle: const TextStyle(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Docelowy slot ręczny:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(SaveGameManager.maxUserSlots, (index) {
                    final slotNum = index + 1;
                    final selected = _selectedTargetSlot == slotNum;
                    return _ModalActionButton(
                      label: 'Slot $slotNum',
                      icon: selected ? Icons.radio_button_checked : Icons.radio_button_off,
                      accentColor: AppColors.goldAccent,
                      enabled: true,
                      filled: selected,
                      onPressed: () => setState(() => _selectedTargetSlot = slotNum),
                    );
                  }),
                ),
                if (_validationResult != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isValid ? AppColors.statusSuccess : AppColors.crimsonAlert)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isValid ? AppColors.statusSuccess : AppColors.crimsonAlert)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    child: isValid && slotMeta != null
                        ? Text(
                            '✓ Plik zweryfikowany: ${slotMeta.playerTeamName ?? 'Kariera'} • '
                            'Data: ${slotMeta.formattedDate} • Budżet: ${slotMeta.formattedCashBalance}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.statusSuccess,
                            ),
                          )
                        : Text(
                            _validationResult!.errorMessage ?? 'Niepoprawny plik .json',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.crimsonAlert,
                            ),
                          ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _ModalActionButton(
                      label: 'Anuluj',
                      icon: Icons.close,
                      accentColor: AppColors.textSecondary,
                      enabled: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    _ModalActionButton(
                      label: 'Importuj do Slotu $_selectedTargetSlot',
                      icon: Icons.check_rounded,
                      accentColor: AppColors.statusSuccess,
                      enabled: isValid,
                      filled: isValid,
                      onPressed: () {
                        Navigator.of(context).pop(
                          _ImportDialogResult(
                            jsonContent: _jsonController.text,
                            targetSlotNumber: _selectedTargetSlot,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
