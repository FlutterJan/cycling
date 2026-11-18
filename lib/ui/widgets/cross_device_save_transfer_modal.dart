import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/career/career_save.dart';
import '../../services/database/cloud_cross_save_json_sync_adapter.dart';

/// Zakładki okna transferu skompresowanych archiwów zapisu `.ppmsave.gz`.
enum CrossDeviceTransferTab {
  exportArchive,
  importArchive,
  portableToken;

  String get labelPl {
    switch (this) {
      case CrossDeviceTransferTab.exportArchive:
        return 'Eksport .ppmsave.gz';
      case CrossDeviceTransferTab.importArchive:
        return 'Import .ppmsave.gz';
      case CrossDeviceTransferTab.portableToken:
        return 'Token PPMCS1 / Chmura';
    }
  }

  IconData get icon {
    switch (this) {
      case CrossDeviceTransferTab.exportArchive:
        return Icons.file_upload_outlined;
      case CrossDeviceTransferTab.importArchive:
        return Icons.file_download_outlined;
      case CrossDeviceTransferTab.portableToken:
        return Icons.qr_code_2_rounded;
    }
  }
}

/// Wynik operacji wykonanej w oknie transferu zapisów między urządzeniami.
enum CrossDeviceTransferModalAction {
  exportedFile,
  importedSave,
  copiedToken,
  syncedCloud,
  dismissed,
}

/// Szczegółowy rezultat zwracany po zamknięciu [CrossDeviceSaveTransferModal].
class CrossDeviceSaveTransferResult {
  final CrossDeviceTransferModalAction action;
  final File? exportedFile;
  final CrossSaveCompressedPacket? packet;
  final Map<String, dynamic>? importedSaveJson;
  final String? portableToken;

  const CrossDeviceSaveTransferResult({
    required this.action,
    this.exportedFile,
    this.packet,
    this.importedSaveJson,
    this.portableToken,
  });
}

/// Wpis wykrytego pliku `.ppmsave.gz` w wybranym katalogu na urządzeniu.
class _DiscoveredArchiveFile {
  final File file;
  final String fileName;
  final int sizeBytes;
  final DateTime modifiedAt;

  const _DiscoveredArchiveFile({
    required this.file,
    required this.fileName,
    required this.sizeBytes,
    required this.modifiedAt,
  });
}

/// Wyświetla modal eksportu i importu skompresowanych archiwów zapisu `.ppmsave.gz`.
Future<CrossDeviceSaveTransferResult?> showCrossDeviceSaveTransferModal(
  BuildContext context, {
  Map<String, dynamic>? currentSaveJson,
  CareerSave? currentCareerSave,
  String? initialDirectoryPath,
  CloudCrossSaveJsonSyncAdapter? adapter,
  CrossDeviceTransferTab initialTab = CrossDeviceTransferTab.exportArchive,
  ValueChanged<Map<String, dynamic>>? onSaveImported,
}) {
  return showDialog<CrossDeviceSaveTransferResult>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) => CrossDeviceSaveTransferModal(
      currentSaveJson: currentSaveJson,
      currentCareerSave: currentCareerSave,
      initialDirectoryPath: initialDirectoryPath,
      adapter: adapter,
      initialTab: initialTab,
      onSaveImported: onSaveImported,
    ),
  );
}

/// Produkcyjne okno eksportu i importu skompresowanych archiwów zapisu `.ppmsave.gz`
/// z pełną weryfikacją sum kontrolnych `FNV-1a64` + `CRC-32`, wyborem poziomu kompresji GZIP,
/// skanerem katalogu i obsługą przenośnych tokenów `PPMCS1:`.
class CrossDeviceSaveTransferModal extends ConsumerStatefulWidget {
  final Map<String, dynamic>? currentSaveJson;
  final CareerSave? currentCareerSave;
  final String? initialDirectoryPath;
  final CloudCrossSaveJsonSyncAdapter? adapter;
  final CrossDeviceTransferTab initialTab;
  final ValueChanged<Map<String, dynamic>>? onSaveImported;

  const CrossDeviceSaveTransferModal({
    super.key,
    this.currentSaveJson,
    this.currentCareerSave,
    this.initialDirectoryPath,
    this.adapter,
    this.initialTab = CrossDeviceTransferTab.exportArchive,
    this.onSaveImported,
  });

  @override
  ConsumerState<CrossDeviceSaveTransferModal> createState() =>
      _CrossDeviceSaveTransferModalState();
}

class _CrossDeviceSaveTransferModalState
    extends ConsumerState<CrossDeviceSaveTransferModal> {
  static const TextStyle _interBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  late CrossDeviceTransferTab _activeTab;
  late CrossSaveDevicePlatform _targetPlatform;
  int _gzipLevel = 9;
  bool _isBusy = false;

  late final TextEditingController _directoryController;
  late final TextEditingController _exportFileNameController;
  late final TextEditingController _importFilePathController;
  late final TextEditingController _tokenController;

  CrossSaveCompressedPacket? _previewPacket;
  String? _previewToken;
  File? _lastExportedFile;

  List<_DiscoveredArchiveFile> _discoveredFiles = const [];
  CrossSaveCompressedPacket? _inspectedImportPacket;
  Map<String, dynamic>? _inspectedImportJson;
  CrossSaveConflictResolutionStrategy _conflictStrategy =
      CrossSaveConflictResolutionStrategy.preferCloudRemote;

  String? _statusBannerMessage;
  bool _statusBannerIsError = false;

  Map<String, dynamic>? get _resolvedCurrentSaveJson {
    if (widget.currentSaveJson != null) return widget.currentSaveJson;
    if (widget.currentCareerSave != null) {
      return widget.currentCareerSave!.toJson();
    }
    return null;
  }

  CloudCrossSaveJsonSyncAdapter _buildAdapter() {
    return widget.adapter ?? CloudCrossSaveJsonSyncAdapter();
  }

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _targetPlatform = CrossSaveDevicePlatform.detectCurrent();

    final initialDir =
        widget.initialDirectoryPath ?? Directory.systemTemp.path;
    _directoryController = TextEditingController(text: initialDir);

    final saveJson = _resolvedCurrentSaveJson;
    final rawId = (saveJson?['saveId'] as String?) ??
        (saveJson?['id'] as String?) ??
        'kariera_ppm';
    final safeId = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    _exportFileNameController = TextEditingController(
      text: '$safeId$kCrossSaveFileExtension',
    );
    _importFilePathController = TextEditingController(
      text: '$initialDir${Platform.pathSeparator}$safeId$kCrossSaveFileExtension',
    );
    _tokenController = TextEditingController();

    _rebuildExportPreview();
    if (widget.initialDirectoryPath == null) {
      _resolveDefaultDirectory();
    } else {
      _scanDirectoryForArchives(silent: true);
    }
  }

  @override
  void dispose() {
    _directoryController.dispose();
    _exportFileNameController.dispose();
    _importFilePathController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _resolveDefaultDirectory() async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final exportDir = Directory(
        '${docsDir.path}${Platform.pathSeparator}ProPelotonManager${Platform.pathSeparator}CrossSave',
      );
      if (!mounted) return;
      if (widget.initialDirectoryPath == null) {
        _directoryController.text = exportDir.path;
        final fileName = _exportFileNameController.text.trim();
        if (fileName.isNotEmpty) {
          _importFilePathController.text =
              '${exportDir.path}${Platform.pathSeparator}$fileName';
        }
        await _scanDirectoryForArchives(silent: true);
      }
    } catch (_) {
      // W środowisku testowym lub bez pluginu path_provider pozostajemy przy katalogu tymczasowym.
      if (mounted) {
        await _scanDirectoryForArchives(silent: true);
      }
    }
  }

  void _rebuildExportPreview() {
    final saveJson = _resolvedCurrentSaveJson;
    if (saveJson == null) {
      _previewPacket = null;
      _previewToken = null;
      return;
    }
    try {
      final adapter = _buildAdapter();
      final syncState = ref.read(cloudCrossSaveSyncProvider);
      final packet = adapter.compressRawJson(
        jsonMap: saveJson,
        sourceDevice: syncState.currentDevice.copyWith(
          platform: _targetPlatform,
        ),
        compressionLevel: _gzipLevel,
      );
      _previewPacket = packet;
      _previewToken = adapter.encodePortableToken(packet);
    } catch (e) {
      _previewPacket = null;
      _previewToken = null;
      _setStatus('Nie udało się zbudować podglądu archiwum: $e', isError: true);
    }
  }

  void _setStatus(String message, {bool isError = false}) {
    if (!mounted) return;
    setState(() {
      _statusBannerMessage = message;
      _statusBannerIsError = isError;
    });
  }

  String _normalizedExportFileName() {
    final raw = _exportFileNameController.text.trim();
    final base = raw.isEmpty ? 'kariera_ppm' : raw;
    if (base.toLowerCase().endsWith(kCrossSaveFileExtension)) {
      return base;
    }
    if (base.toLowerCase().endsWith('.gz')) {
      return base;
    }
    return '$base$kCrossSaveFileExtension';
  }

  Future<void> _handleExportArchive() async {
    final packet = _previewPacket;
    if (packet == null) {
      _setStatus(
        'Brak aktywnego zapisu kariery do eksportu.',
        isError: true,
      );
      return;
    }

    final dirPath = _directoryController.text.trim();
    if (dirPath.isEmpty) {
      _setStatus('Podaj docelową ścieżkę katalogu eksportu.', isError: true);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final adapter = _buildAdapter();
      final fileName = _normalizedExportFileName();
      final outFile = await adapter.exportToCompressedFile(
        packet: packet,
        targetDirectory: Directory(dirPath),
        customFileName: fileName,
      );
      final fileSize = await outFile.length();
      if (!mounted) return;
      setState(() {
        _lastExportedFile = outFile;
        _importFilePathController.text = outFile.path;
        _isBusy = false;
      });
      _setStatus(
        'Wyeksportowano archiwum $fileName (${_formatBytes(fileSize)}) z sumą CRC-32 ${packet.metadata.crc32Checksum}.',
      );
      await _scanDirectoryForArchives(silent: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setStatus('Błąd eksportu pliku .ppmsave.gz: $e', isError: true);
    }
  }

  Future<void> _handleCopyToken() async {
    final token = _previewToken;
    if (token == null || token.isEmpty) {
      _setStatus('Brak wygenerowanego tokenu PPMCS1.', isError: true);
      return;
    }
    await Clipboard.setData(ClipboardData(text: token));
    if (!mounted) return;
    _setStatus(
      'Skopiowano przenośny token $kCrossSaveTokenPrefix (${token.length} znaków) do schowka.',
    );
  }

  Future<void> _handleCopyExportedPath() async {
    final file = _lastExportedFile;
    if (file == null) return;
    await Clipboard.setData(ClipboardData(text: file.path));
    if (!mounted) return;
    _setStatus('Skopiowano ścieżkę pliku: ${file.path}');
  }

  Future<void> _scanDirectoryForArchives({bool silent = false}) async {
    final dirPath = _directoryController.text.trim();
    if (dirPath.isEmpty) {
      if (!silent) {
        _setStatus('Podaj ścieżkę katalogu do przeskanowania.', isError: true);
      }
      return;
    }

    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        if (!mounted) return;
        setState(() => _discoveredFiles = const []);
        if (!silent) {
          _setStatus('Katalog nie istnieje: $dirPath', isError: true);
        }
        return;
      }

      final entities = await dir.list(followLinks: false).toList();
      final archives = <_DiscoveredArchiveFile>[];
      for (final entity in entities) {
        if (entity is File &&
            entity.path.toLowerCase().endsWith(kCrossSaveFileExtension)) {
          final stat = await entity.stat();
          final segments = entity.uri.pathSegments;
          final name = segments.isNotEmpty && segments.last.isNotEmpty
              ? segments.last
              : entity.path.split(Platform.pathSeparator).last;
          archives.add(
            _DiscoveredArchiveFile(
              file: entity,
              fileName: name,
              sizeBytes: stat.size,
              modifiedAt: stat.modified,
            ),
          );
        }
      }
      archives.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
      if (!mounted) return;
      setState(() => _discoveredFiles = archives);
      if (!silent) {
        _setStatus(
          archives.isEmpty
              ? 'Nie znaleziono plików $kCrossSaveFileExtension w katalogu.'
              : 'Znaleziono ${archives.length} archiwów $kCrossSaveFileExtension.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        _setStatus('Błąd skanowania katalogu: $e', isError: true);
      }
    }
  }

  Future<void> _handleInspectImportFile([String? overridePath]) async {
    final path = (overridePath ?? _importFilePathController.text).trim();
    if (path.isEmpty) {
      _setStatus('Podaj ścieżkę do pliku .ppmsave.gz.', isError: true);
      return;
    }
    if (overridePath != null) {
      _importFilePathController.text = overridePath;
    }

    setState(() => _isBusy = true);
    try {
      final adapter = _buildAdapter();
      final packet = await adapter.importFromCompressedFile(File(path));
      final json = adapter.decompressToJson(packet);
      if (!mounted) return;
      setState(() {
        _inspectedImportPacket = packet;
        _inspectedImportJson = json;
        _isBusy = false;
      });
      _setStatus(
        'Zweryfikowano archiwum "${packet.metadata.saveName}" (FNV-1a64 & CRC-32 poprawne).',
      );
    } on CrossSaveIntegrityException catch (e) {
      if (!mounted) return;
      setState(() {
        _inspectedImportPacket = null;
        _inspectedImportJson = null;
        _isBusy = false;
      });
      _setStatus('Weryfikacja integralności nie powiodła się: ${e.message}',
          isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inspectedImportPacket = null;
        _inspectedImportJson = null;
        _isBusy = false;
      });
      _setStatus('Nie można odczytać pliku: $e', isError: true);
    }
  }

  Future<void> _handleConfirmImport() async {
    final json = _inspectedImportJson;
    final packet = _inspectedImportPacket;
    if (json == null || packet == null) return;

    widget.onSaveImported?.call(json);
    if (!mounted) return;
    Navigator.of(context).pop(
      CrossDeviceSaveTransferResult(
        action: CrossDeviceTransferModalAction.importedSave,
        packet: packet,
        importedSaveJson: json,
      ),
    );
  }

  Future<void> _handleDecodeToken() async {
    final raw = _tokenController.text.trim();
    if (raw.isEmpty) {
      _setStatus('Wklej token zaczynający się od $kCrossSaveTokenPrefix.',
          isError: true);
      return;
    }

    setState(() => _isBusy = true);
    try {
      final adapter = _buildAdapter();
      final packet = adapter.decodePortableToken(raw);
      final json = adapter.decompressToJson(packet);
      if (!mounted) return;
      setState(() {
        _inspectedImportPacket = packet;
        _inspectedImportJson = json;
        _isBusy = false;
      });
      _setStatus(
        'Token PPMCS1 zweryfikowany pomyślnie (${packet.metadata.saveName}).',
      );
    } on CrossSaveIntegrityException catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setStatus('Błędny token: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _setStatus('Nie udało się zdekodować tokenu: $e', isError: true);
    }
  }

  Future<void> _handlePasteTokenFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (!mounted) return;
    if (text.isEmpty) {
      _setStatus('Schowek jest pusty.', isError: true);
      return;
    }
    _tokenController.text = text;
    await _handleDecodeToken();
  }

  Future<void> _handleUploadToCloud() async {
    final saveJson = _resolvedCurrentSaveJson;
    if (saveJson == null) {
      _setStatus('Brak aktywnego zapisu do wysłania do chmury.', isError: true);
      return;
    }
    setState(() => _isBusy = true);
    final notifier = ref.read(cloudCrossSaveSyncProvider.notifier);
    final slotKey = (saveJson['saveId'] as String?) ??
        (saveJson['id'] as String?) ??
        'slot_cross_device';
    final receipt = await notifier.syncUploadSaveJson(
      slotKey: slotKey,
      saveJson: saveJson,
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (receipt.success) {
      _setStatus(receipt.messagePl);
    } else {
      _setStatus(receipt.messagePl, isError: true);
    }
  }

  Future<void> _handleDownloadCloudSlot(String slotKey) async {
    setState(() => _isBusy = true);
    final notifier = ref.read(cloudCrossSaveSyncProvider.notifier);
    final json = await notifier.syncDownloadSaveJson(slotKey);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (json != null) {
      widget.onSaveImported?.call(json);
      Navigator.of(context).pop(
        CrossDeviceSaveTransferResult(
          action: CrossDeviceTransferModalAction.syncedCloud,
          importedSaveJson: json,
        ),
      );
    } else {
      final err = ref.read(cloudCrossSaveSyncProvider).errorMessage;
      _setStatus(err ?? 'Nie udało się pobrać slotu z chmury.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(cloudCrossSaveSyncProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 620;
          final isWide = constraints.maxWidth >= 900;
          final maxModalWidth = isWide ? 1040.0 : 860.0;
          final maxModalHeight =
              (constraints.maxHeight * 0.92).clamp(420.0, 820.0);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxModalWidth,
                maxHeight: maxModalHeight,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderColor, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 32,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(isCompact),
                    _buildTabBar(isCompact),
                    if (_statusBannerMessage != null) _buildStatusBanner(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(isCompact ? 14 : 20),
                        child: _buildBody(
                          isCompact: isCompact,
                          isWide: isWide,
                          syncState: syncState,
                        ),
                      ),
                    ),
                    _buildFooter(isCompact),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primaryAccent.withValues(alpha: 0.45),
              ),
            ),
            child: const Icon(
              Icons.sync_alt_rounded,
              color: AppColors.goldAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer Zapisów Cross-Device (.ppmsave.gz)',
                  style: _interBase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: isCompact ? 15 : 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Kompresja GZIP, weryfikacja FNV-1a64 + CRC-32 i wymiana PC <-> Mac <-> Mobile',
                  style: _interBase.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isCompact ? 11.5 : 12.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ModalIconButton(
            tooltip: 'Zamknij okno',
            icon: Icons.close_rounded,
            onPressed: _isBusy
                ? null
                : () => Navigator.of(context).pop(
                      const CrossDeviceSaveTransferResult(
                        action: CrossDeviceTransferModalAction.dismissed,
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isCompact) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: 10,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: CrossDeviceTransferTab.values.map((tab) {
            final selected = _activeTab == tab;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TransferTabPill(
                label: tab.labelPl,
                icon: tab.icon,
                selected: selected,
                onTap: () => setState(() => _activeTab = tab),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final msg = _statusBannerMessage;
    if (msg == null) return const SizedBox.shrink();
    final accent = _statusBannerIsError
        ? AppColors.crimsonAlert
        : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: accent.withValues(alpha: 0.4), width: 1.0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusBannerIsError
                ? Icons.error_outline_rounded
                : Icons.verified_outlined,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: _interBase.copyWith(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _statusBannerMessage = null),
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: 'Ukryj komunikat',
          ),
        ],
      ),
    );
  }

  Widget _buildBody({
    required bool isCompact,
    required bool isWide,
    required CloudCrossSaveSyncState syncState,
  }) {
    switch (_activeTab) {
      case CrossDeviceTransferTab.exportArchive:
        return _buildExportTab(isCompact: isCompact, isWide: isWide);
      case CrossDeviceTransferTab.importArchive:
        return _buildImportTab(isCompact: isCompact, isWide: isWide);
      case CrossDeviceTransferTab.portableToken:
        return _buildTokenAndCloudTab(
          isCompact: isCompact,
          isWide: isWide,
          syncState: syncState,
        );
    }
  }

  Widget _buildExportTab({required bool isCompact, required bool isWide}) {
    final configCard = _buildExportConfigCard(isCompact);
    final previewCard = _buildExportPreviewCard(isCompact);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: configCard),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: previewCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        configCard,
        const SizedBox(height: 16),
        previewCard,
      ],
    );
  }

  Widget _buildExportConfigCard(bool isCompact) {
    final hasSave = _resolvedCurrentSaveJson != null;

    return _SectionCard(
      title: 'Konfiguracja Eksportu Archiwum',
      subtitle: 'Wybierz platformę docelową, poziom kompresji GZIP oraz ścieżkę zapisu.',
      icon: Icons.tune_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasSave) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.amberWarning.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.amberWarning,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Brak aktywnego zapisu kariery. Możesz zaimportować plik .ppmsave.gz lub token PPMCS1.',
                      style: _interBase.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            'Platforma docelowa',
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: CrossSaveDevicePlatform.values.map((platform) {
              return _PlatformChip(
                platform: platform,
                selected: _targetPlatform == platform,
                onTap: () {
                  setState(() {
                    _targetPlatform = platform;
                    _rebuildExportPreview();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Poziom kompresji GZIP',
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CompressionLevelChip(
                level: 1,
                label: 'Poziom 1 • Szybka',
                selected: _gzipLevel == 1,
                onTap: () {
                  setState(() {
                    _gzipLevel = 1;
                    _rebuildExportPreview();
                  });
                },
              ),
              _CompressionLevelChip(
                level: 6,
                label: 'Poziom 6 • Zbalansowana',
                selected: _gzipLevel == 6,
                onTap: () {
                  setState(() {
                    _gzipLevel = 6;
                    _rebuildExportPreview();
                  });
                },
              ),
              _CompressionLevelChip(
                level: 9,
                label: 'Poziom 9 • Maksymalna',
                selected: _gzipLevel == 9,
                onTap: () {
                  setState(() {
                    _gzipLevel = 9;
                    _rebuildExportPreview();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _directoryController,
            label: 'Katalog docelowy',
            hint: 'Ścieżka folderu na pliki .ppmsave.gz',
            prefixIcon: Icons.folder_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _exportFileNameController,
            label: 'Nazwa pliku archiwum',
            hint: 'kariera_2026.ppmsave.gz',
            prefixIcon: Icons.archive_outlined,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: _isBusy ? 'Eksportowanie...' : 'Eksportuj .ppmsave.gz',
                icon: Icons.save_alt_rounded,
                variant: _ActionButtonVariant.primary,
                enabled: hasSave && !_isBusy,
                onPressed: _handleExportArchive,
              ),
              _ActionButton(
                label: 'Kopiuj token PPMCS1',
                icon: Icons.copy_rounded,
                variant: _ActionButtonVariant.secondary,
                enabled: hasSave && _previewToken != null && !_isBusy,
                onPressed: _handleCopyToken,
              ),
              if (_lastExportedFile != null)
                _ActionButton(
                  label: 'Kopiuj ścieżkę pliku',
                  icon: Icons.link_rounded,
                  variant: _ActionButtonVariant.subtle,
                  enabled: !_isBusy,
                  onPressed: _handleCopyExportedPath,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExportPreviewCard(bool isCompact) {
    final packet = _previewPacket;
    return _SectionCard(
      title: 'Telemetria Koperty GZIP',
      subtitle: 'Podgląd rozmiaru, oszczędności pasma i sum kontrolnych.',
      icon: Icons.analytics_outlined,
      child: packet == null
          ? const _EmptyPreviewPlaceholder(
              icon: Icons.inventory_2_outlined,
              message: 'Brak danych zapisu do wyliczenia koperty GZIP.',
            )
          : _EnvelopeTelemetryView(
              metadata: packet.metadata,
              isCompact: isCompact,
              verified: true,
            ),
    );
  }

  Widget _buildImportTab({required bool isCompact, required bool isWide}) {
    final pickerCard = _SectionCard(
      title: 'Wybierz Archiwum .ppmsave.gz',
      subtitle: 'Wczytaj plik bezpośrednio ze ścieżki lub wybierz ze skanowanego folderu.',
      icon: Icons.folder_open_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _importFilePathController,
            label: 'Ścieżka do pliku .ppmsave.gz',
            hint: 'np. C:\\Saves\\kariera.ppmsave.gz',
            prefixIcon: Icons.insert_drive_file_outlined,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Weryfikuj plik',
                icon: Icons.verified_user_outlined,
                variant: _ActionButtonVariant.primary,
                enabled: !_isBusy,
                onPressed: () => _handleInspectImportFile(),
              ),
              _ActionButton(
                label: 'Skanuj katalog',
                icon: Icons.refresh_rounded,
                variant: _ActionButtonVariant.secondary,
                enabled: !_isBusy,
                onPressed: () => _scanDirectoryForArchives(silent: false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Wykryte archiwa w katalogu (${_discoveredFiles.length})',
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_discoveredFiles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                'Brak wykrytych plików $kCrossSaveFileExtension w bieżącym katalogu.',
                style: _interBase.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _discoveredFiles.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _discoveredFiles[index];
                  final isSelected =
                      _importFilePathController.text.trim() == item.file.path;
                  return _DiscoveredArchiveTile(
                    fileName: item.fileName,
                    sizeLabel: _formatBytes(item.sizeBytes),
                    dateLabel: _formatDateTime(item.modifiedAt),
                    selected: isSelected,
                    onTap: () => _handleInspectImportFile(item.file.path),
                  );
                },
              ),
            ),
        ],
      ),
    );

    final inspectionCard = _buildImportInspectionCard(isCompact);

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: pickerCard),
          const SizedBox(width: 16),
          Expanded(flex: 5, child: inspectionCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        pickerCard,
        const SizedBox(height: 16),
        inspectionCard,
      ],
    );
  }

  Widget _buildImportInspectionCard(bool isCompact) {
    final packet = _inspectedImportPacket;
    return _SectionCard(
      title: 'Inspekcja i Integralność',
      subtitle: 'Weryfikacja sum kontrolnych przed nadpisaniem lokalnego zapisu.',
      icon: Icons.security_rounded,
      child: packet == null
          ? const _EmptyPreviewPlaceholder(
              icon: Icons.manage_search_rounded,
              message:
                  'Wybierz i zweryfikuj plik .ppmsave.gz, aby zobaczyć metadane oraz sumy kontrolne.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EnvelopeTelemetryView(
                  metadata: packet.metadata,
                  isCompact: isCompact,
                  verified: true,
                ),
                const SizedBox(height: 14),
                Text(
                  'Strategia przy konflikcie zapisu',
                  style: _interBase.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CrossSaveConflictResolutionStrategy.preferCloudRemote,
                    CrossSaveConflictResolutionStrategy.keepNewestTimestamp,
                    CrossSaveConflictResolutionStrategy.preferLocalDevice,
                  ].map((strategy) {
                    return _CompressionLevelChip(
                      level: strategy.index,
                      label: strategy.labelPl,
                      selected: _conflictStrategy == strategy,
                      onTap: () =>
                          setState(() => _conflictStrategy = strategy),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  label: 'Załaduj zapis do gry',
                  icon: Icons.check_circle_outline_rounded,
                  variant: _ActionButtonVariant.success,
                  enabled: !_isBusy && _inspectedImportJson != null,
                  onPressed: _handleConfirmImport,
                ),
              ],
            ),
    );
  }

  Widget _buildTokenAndCloudTab({
    required bool isCompact,
    required bool isWide,
    required CloudCrossSaveSyncState syncState,
  }) {
    final tokenCard = _SectionCard(
      title: 'Import Przenośnym Tokenem PPMCS1',
      subtitle: 'Wklej tekstowy token skopiowany z innego urządzenia (PC, Mac lub Mobile).',
      icon: Icons.key_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _tokenController,
            label: 'Token transferowy ($kCrossSaveTokenPrefix...)',
            hint: '${kCrossSaveTokenPrefix}H4sIAAAAAAAA...',
            prefixIcon: Icons.vpn_key_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Dekoduj token',
                icon: Icons.lock_open_rounded,
                variant: _ActionButtonVariant.primary,
                enabled: !_isBusy,
                onPressed: _handleDecodeToken,
              ),
              _ActionButton(
                label: 'Wklej ze schowka',
                icon: Icons.content_paste_rounded,
                variant: _ActionButtonVariant.secondary,
                enabled: !_isBusy,
                onPressed: _handlePasteTokenFromClipboard,
              ),
              if (_inspectedImportJson != null)
                _ActionButton(
                  label: 'Załaduj zdekodowany zapis',
                  icon: Icons.check_circle_outline_rounded,
                  variant: _ActionButtonVariant.success,
                  enabled: !_isBusy,
                  onPressed: _handleConfirmImport,
                ),
            ],
          ),
        ],
      ),
    );

    final cloudCard = _SectionCard(
      title: 'Chmura Cross-Save (${syncState.cloudSlots.length} slotów)',
      subtitle: 'Bezpośrednia synchronizacja z przekaźnikiem chmurowym.',
      icon: Icons.cloud_sync_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionButton(
                label: 'Wyślij bieżący zapis do chmury',
                icon: Icons.cloud_upload_outlined,
                variant: _ActionButtonVariant.primary,
                enabled: _resolvedCurrentSaveJson != null && !_isBusy,
                onPressed: _handleUploadToCloud,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (syncState.cloudSlots.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Text(
                'Brak zapisów w chmurze Cross-Save.',
                style: _interBase.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: syncState.cloudSlots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final slot = syncState.cloudSlots[index];
                return _CloudSlotTile(
                  slot: slot,
                  sizeLabel: _formatBytes(slot.metadata.compressedBytes),
                  onDownload: _isBusy
                      ? null
                      : () => _handleDownloadCloudSlot(slot.slotKey),
                );
              },
            ),
        ],
      ),
    );

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: tokenCard),
          const SizedBox(width: 16),
          Expanded(child: cloudCard),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tokenCard,
        const SizedBox(height: 16),
        cloudCard,
      ],
    );
  }

  Widget _buildFooter(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor, width: 1.0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Format: $kCrossSaveFileExtension • GZIP Poziom $_gzipLevel',
              style: _interBase.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          _ActionButton(
            label: 'Zamknij',
            icon: Icons.close_rounded,
            variant: _ActionButtonVariant.subtle,
            enabled: !_isBusy,
            onPressed: () {
              Navigator.of(context).pop(
                CrossDeviceSaveTransferResult(
                  action: _lastExportedFile != null
                      ? CrossDeviceTransferModalAction.exportedFile
                      : CrossDeviceTransferModalAction.dismissed,
                  exportedFile: _lastExportedFile,
                  packet: _previewPacket,
                  portableToken: _previewToken,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _interBase.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: _interBase.copyWith(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _interBase.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 12.5,
            ),
            prefixIcon: Icon(
              prefixIcon,
              color: AppColors.textSecondary,
              size: 18,
            ),
            filled: true,
            fillColor: AppColors.surfaceLight,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  static String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              Icon(icon, color: AppColors.goldAccent, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _EnvelopeTelemetryView extends StatelessWidget {
  final CrossSaveEnvelopeMetadata metadata;
  final bool isCompact;
  final bool verified;

  const _EnvelopeTelemetryView({
    required this.metadata,
    required this.isCompact,
    required this.verified,
  });

  @override
  Widget build(BuildContext context) {
    final savedPercent = metadata.bandwidthSavedPercent;
    final ratio = metadata.compressionRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metadata.saveName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: (verified
                              ? AppColors.statusSuccess
                              : AppColors.amberWarning)
                          .withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      verified ? 'ZWERYFIKOWANO' : 'NIEZWERYFIKOWANO',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: verified
                            ? AppColors.statusSuccess
                            : AppColors.amberWarning,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${metadata.teamName} • Menedżer: ${metadata.managerName} • Sezon ${metadata.seasonYear}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Źródło: ${metadata.sourcePlatform.labelPl} (${metadata.sourceDeviceName})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetricBox(
              label: 'JSON surowy',
              value: _CrossDeviceSaveTransferModalState._formatBytes(
                metadata.uncompressedBytes,
              ),
              color: AppColors.textPrimary,
            ),
            _MetricBox(
              label: 'Archiwum GZIP',
              value: _CrossDeviceSaveTransferModalState._formatBytes(
                metadata.compressedBytes,
              ),
              color: AppColors.accentBlue,
            ),
            _MetricBox(
              label: 'Oszczędność',
              value: '${savedPercent.toStringAsFixed(1)}% (${ratio.toStringAsFixed(1)}x)',
              color: AppColors.statusSuccess,
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: (savedPercent / 100.0).clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.statusSuccess,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _ChecksumRow(label: 'FNV-1a64', value: metadata.fnv1a64Checksum),
        const SizedBox(height: 6),
        _ChecksumRow(label: 'CRC-32', value: metadata.crc32Checksum),
      ],
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: color,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecksumRow extends StatelessWidget {
  final String label;
  final String value;

  const _ChecksumRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              color: AppColors.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: AppColors.cyanAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreviewPlaceholder extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyPreviewPlaceholder({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 30),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferTabPill extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TransferTabPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_TransferTabPill> createState() => _TransferTabPillState();
}

class _TransferTabPillState extends State<_TransferTabPill> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.9)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.primaryAccent
            : _hovered
                ? AppColors.textSecondary.withValues(alpha: 0.5)
                : AppColors.cardBorder;

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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.selected
                    ? Colors.white
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: widget.selected
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight:
                      widget.selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformChip extends StatefulWidget {
  final CrossSaveDevicePlatform platform;
  final bool selected;
  final VoidCallback onTap;

  const _PlatformChip({
    required this.platform,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_PlatformChip> createState() => _PlatformChipState();
}

class _PlatformChipState extends State<_PlatformChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.accentBlue.withValues(alpha: 0.16)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.accentBlue
            : AppColors.cardBorder;

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.platform.icon,
                size: 15,
                color: widget.selected
                    ? AppColors.accentBlue
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                widget.platform.labelPl,
                style: TextStyle(
                  fontFamily: 'Inter',
                  letterSpacing: -0.2,
                  color: widget.selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      widget.selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompressionLevelChip extends StatefulWidget {
  final int level;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CompressionLevelChip({
    required this.level,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_CompressionLevelChip> createState() => _CompressionLevelChipState();
}

class _CompressionLevelChipState extends State<_CompressionLevelChip> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.goldAccent.withValues(alpha: 0.16)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.85)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final borderColor = _focused
        ? AppColors.accentBlue
        : widget.selected
            ? AppColors.goldAccent
            : AppColors.cardBorder;

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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: widget.selected
                  ? AppColors.goldAccent
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveredArchiveTile extends StatefulWidget {
  final String fileName;
  final String sizeLabel;
  final String dateLabel;
  final bool selected;
  final VoidCallback onTap;

  const _DiscoveredArchiveTile({
    required this.fileName,
    required this.sizeLabel,
    required this.dateLabel,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_DiscoveredArchiveTile> createState() => _DiscoveredArchiveTileState();
}

class _DiscoveredArchiveTileState extends State<_DiscoveredArchiveTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primaryAccent.withValues(alpha: 0.16)
        : _pressed
            ? AppColors.surfaceLight.withValues(alpha: 0.8)
            : _hovered
                ? AppColors.surfaceLight
                : AppColors.background;
    final borderColor = _focused
        ? AppColors.goldAccent
        : widget.selected
            ? AppColors.primaryAccent
            : AppColors.cardBorder;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.archive_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fileName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: AppColors.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.dateLabel,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        letterSpacing: -0.2,
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.sizeLabel,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  color: AppColors.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CloudSlotTile extends StatelessWidget {
  final CrossSaveCloudSlotRecord slot;
  final String sizeLabel;
  final VoidCallback? onDownload;

  const _CloudSlotTile({
    required this.slot,
    required this.sizeLabel,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Icon(
            slot.metadata.sourcePlatform.icon,
            color: AppColors.accentBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.metadata.saveName,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textPrimary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${slot.metadata.teamName} • $sizeLabel • v${slot.revisionNumber}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: 'Pobierz',
            icon: Icons.cloud_download_outlined,
            variant: _ActionButtonVariant.secondary,
            enabled: onDownload != null,
            onPressed: onDownload ?? () {},
          ),
        ],
      ),
    );
  }
}

enum _ActionButtonVariant { primary, secondary, success, subtle }

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final _ActionButtonVariant variant;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.variant,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = switch (widget.variant) {
      _ActionButtonVariant.primary => AppColors.primaryAccent,
      _ActionButtonVariant.secondary => AppColors.surfaceLight,
      _ActionButtonVariant.success => AppColors.statusSuccess,
      _ActionButtonVariant.subtle => AppColors.background,
    };

    final bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.4)
        : _pressed
            ? baseColor.withValues(alpha: 0.8)
            : _hovered
                ? Color.lerp(baseColor, Colors.white, 0.08) ?? baseColor
                : baseColor;

    final fgColor = !widget.enabled
        ? AppColors.textSecondary.withValues(alpha: 0.5)
        : widget.variant == _ActionButtonVariant.primary ||
                widget.variant == _ActionButtonVariant.success
            ? Colors.white
            : AppColors.textPrimary;

    final borderColor = !widget.enabled
        ? AppColors.cardBorder.withValues(alpha: 0.5)
        : _focused
            ? AppColors.goldAccent
            : widget.variant == _ActionButtonVariant.secondary ||
                    widget.variant == _ActionButtonVariant.subtle
                ? AppColors.cardBorder
                : baseColor;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      mouseCursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown:
            widget.enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp:
            widget.enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            widget.enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              Icon(widget.icon, size: 16, color: fgColor),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    letterSpacing: -0.2,
                    color: fgColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

class _ModalIconButton extends StatefulWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  const _ModalIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_ModalIconButton> createState() => _ModalIconButtonState();
}

class _ModalIconButtonState extends State<_ModalIconButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final bgColor = !enabled
        ? Colors.transparent
        : _pressed
            ? AppColors.surfaceLight
            : _hovered
                ? AppColors.surfaceLight.withValues(alpha: 0.85)
                : AppColors.background;

    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused ? AppColors.goldAccent : AppColors.cardBorder,
                width: _focused ? 1.5 : 1.0,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: enabled
                  ? AppColors.textPrimary
                  : AppColors.textSecondary.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
