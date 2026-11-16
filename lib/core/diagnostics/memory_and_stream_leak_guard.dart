// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show ProcessInfo;
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Kategoria zasobu monitorowanego przez [MemoryAndStreamLeakGuard].
enum LeakResourceKind {
  isolate('Isolate', Icons.memory_rounded),
  animationController('AnimationController', Icons.animation_rounded),
  streamSubscription('StreamSubscription', Icons.stream_rounded);

  final String label;
  final IconData icon;

  const LeakResourceKind(this.label, this.icon);
}

/// Bieżący status cyklu życia monitorowanego zasobu.
enum LeakResourceStatus {
  active('Aktywny'),
  disposed('Zamknięty'),
  leaked('Wyciek'),
  forceCleaned('Wyczyszczony');

  final String label;

  const LeakResourceStatus(this.label);
}

/// Niemutowalny wpis pojedynczego zasobu śledzonego w trakcie sesji wyścigu 3D.
@immutable
class TrackedResourceEntry {
  final String id;
  final LeakResourceKind kind;
  final String owner;
  final String label;
  final DateTime registeredAt;
  final DateTime? disposedAt;
  final LeakResourceStatus status;
  final String? sessionId;
  final String? notes;

  const TrackedResourceEntry({
    required this.id,
    required this.kind,
    required this.owner,
    required this.label,
    required this.registeredAt,
    required this.status,
    this.disposedAt,
    this.sessionId,
    this.notes,
  });

  TrackedResourceEntry copyWith({
    LeakResourceStatus? status,
    DateTime? disposedAt,
    String? notes,
  }) {
    return TrackedResourceEntry(
      id: id,
      kind: kind,
      owner: owner,
      label: label,
      registeredAt: registeredAt,
      disposedAt: disposedAt ?? this.disposedAt,
      status: status ?? this.status,
      sessionId: sessionId,
      notes: notes ?? this.notes,
    );
  }
}

/// Pojedynczy wykryty wyciek zasobu przy wyjściu z widoku wyścigu 3D.
@immutable
class LeakAuditIssue {
  final String resourceId;
  final LeakResourceKind kind;
  final String owner;
  final String message;
  final bool wasForceCleaned;

  const LeakAuditIssue({
    required this.resourceId,
    required this.kind,
    required this.owner,
    required this.message,
    this.wasForceCleaned = false,
  });
}

/// Raport końcowy z audytu zamykania zasobów przy wyjściu z wyścigu 3D do menedżera.
@immutable
class LeakAuditReport {
  final String sessionId;
  final String? stageName;
  final DateTime auditedAt;
  final int totalTracked;
  final int properlyDisposed;
  final int leakedIsolates;
  final int leakedAnimationControllers;
  final int leakedStreamSubscriptions;
  final int forceCleanedCount;
  final int? rssBytesBeforeExit;
  final int? rssBytesAfterExit;
  final List<LeakAuditIssue> issues;

  const LeakAuditReport({
    required this.sessionId,
    required this.auditedAt,
    required this.totalTracked,
    required this.properlyDisposed,
    required this.leakedIsolates,
    required this.leakedAnimationControllers,
    required this.leakedStreamSubscriptions,
    required this.forceCleanedCount,
    required this.issues,
    this.stageName,
    this.rssBytesBeforeExit,
    this.rssBytesAfterExit,
  });

  int get totalLeaked =>
      leakedIsolates + leakedAnimationControllers + leakedStreamSubscriptions;

  bool get isClean => totalLeaked == 0;

  int? get rssDeltaBytes {
    if (rssBytesBeforeExit == null || rssBytesAfterExit == null) {
      return null;
    }
    return rssBytesAfterExit! - rssBytesBeforeExit!;
  }
}

/// Migawka stanu strażnika pamięci do reaktywnego wyświetlania w UI diagnostycznym.
@immutable
class LeakGuardSnapshot {
  final bool isRace3dSessionActive;
  final String? activeSessionId;
  final String? activeStageName;
  final int activeIsolatesCount;
  final int activeAnimationControllersCount;
  final int activeStreamSubscriptionsCount;
  final int totalDisposedInSession;
  final int totalForceCleanedInSession;
  final List<TrackedResourceEntry> entries;
  final LeakAuditReport? lastAuditReport;

  const LeakGuardSnapshot({
    this.isRace3dSessionActive = false,
    this.activeSessionId,
    this.activeStageName,
    this.activeIsolatesCount = 0,
    this.activeAnimationControllersCount = 0,
    this.activeStreamSubscriptionsCount = 0,
    this.totalDisposedInSession = 0,
    this.totalForceCleanedInSession = 0,
    this.entries = const <TrackedResourceEntry>[],
    this.lastAuditReport,
  });

  int get totalActiveCount =>
      activeIsolatesCount +
      activeAnimationControllersCount +
      activeStreamSubscriptionsCount;

  int get leakedCount => entries
      .where((entry) => entry.status == LeakResourceStatus.leaked)
      .length;
}

class _TrackedResourceRecord {
  TrackedResourceEntry entry;
  Isolate? isolate;
  FutureOr<void> Function()? onIsolateDispose;
  AnimationController? animationController;
  StreamSubscription<dynamic>? streamSubscription;
  FutureOr<void> Function()? onStreamCancel;

  _TrackedResourceRecord({
    required this.entry,
    this.isolate,
    this.onIsolateDispose,
    this.animationController,
    this.streamSubscription,
    this.onStreamCancel,
  });
}

/// Strażnik pamięci monitorujący poprawne zamykanie [Isolate],
/// [AnimationController] oraz [StreamSubscription] przy wyjściu z wyścigu 3D
/// do widoku menedżera.
class MemoryAndStreamLeakGuard {
  MemoryAndStreamLeakGuard();

  static final MemoryAndStreamLeakGuard instance = MemoryAndStreamLeakGuard();

  final Map<String, _TrackedResourceRecord> _records =
      <String, _TrackedResourceRecord>{};

  final ValueNotifier<LeakGuardSnapshot> snapshotNotifier =
      ValueNotifier<LeakGuardSnapshot>(const LeakGuardSnapshot());

  final StreamController<LeakAuditReport> _auditReportController =
      StreamController<LeakAuditReport>.broadcast();

  String? _activeSessionId;
  String? _activeStageName;
  int? _sessionStartRssBytes;
  LeakAuditReport? _lastAuditReport;
  int _sessionCounter = 0;
  bool _isGuardDisposed = false;

  /// Strumień raportów audytu emitowanych po zakończeniu sesji wyścigu 3D.
  Stream<LeakAuditReport> get auditReportStream =>
      _auditReportController.stream;

  /// Aktualna migawka stanu monitorowanych zasobów.
  LeakGuardSnapshot get currentSnapshot => snapshotNotifier.value;

  /// Rozpoczyna nową sesję monitorowania zasobów wyścigu 3D.
  String beginRace3dSession({String? stageId, String? stageName}) {
    _sessionCounter += 1;
    final String sessionId =
        stageId != null && stageId.trim().isNotEmpty
            ? '${stageId.trim()}_$_sessionCounter'
            : 'race3d_session_$_sessionCounter';
    _activeSessionId = sessionId;
    _activeStageName = stageName?.trim().isNotEmpty == true
        ? stageName!.trim()
        : 'Wyścig 3D #$sessionId';
    _sessionStartRssBytes = _tryReadProcessRssBytes();
    _emitSnapshot();
    return sessionId;
  }

  /// Rejestruje aktywny wątek [Isolate] powiązany z symulacją wyścigu 3D.
  void registerIsolate(
    String id, {
    Isolate? isolate,
    FutureOr<void> Function()? onDispose,
    String owner = 'IsolateSimulationWorker',
    String? label,
  }) {
    final String normalizedId = _normalizeId(id);
    _records[normalizedId] = _TrackedResourceRecord(
      entry: TrackedResourceEntry(
        id: normalizedId,
        kind: LeakResourceKind.isolate,
        owner: owner,
        label: label ?? normalizedId,
        registeredAt: DateTime.now(),
        status: LeakResourceStatus.active,
        sessionId: _activeSessionId,
      ),
      isolate: isolate,
      onIsolateDispose: onDispose,
    );
    _emitSnapshot();
  }

  /// Oznacza wątek [Isolate] jako poprawnie zamknięty.
  void markIsolateClosed(String id) {
    _markDisposed(id, expectedKind: LeakResourceKind.isolate);
  }

  /// Rejestruje [AnimationController] używany w widoku 3D lub HUD wyścigu.
  void registerAnimationController(
    String id,
    AnimationController controller, {
    String owner = 'Race3DViewportWidget',
    String? label,
  }) {
    final String normalizedId = _normalizeId(id);
    _records[normalizedId] = _TrackedResourceRecord(
      entry: TrackedResourceEntry(
        id: normalizedId,
        kind: LeakResourceKind.animationController,
        owner: owner,
        label: label ?? normalizedId,
        registeredAt: DateTime.now(),
        status: LeakResourceStatus.active,
        sessionId: _activeSessionId,
      ),
      animationController: controller,
    );
    _emitSnapshot();
  }

  /// Oznacza [AnimationController] jako poprawnie zwolniony przez `dispose()`.
  void markAnimationControllerDisposed(String id) {
    _markDisposed(id, expectedKind: LeakResourceKind.animationController);
  }

  /// Rejestruje [StreamSubscription] nasłuchującą zdarzeń wyścigu 3D.
  void registerStreamSubscription(
    String id,
    StreamSubscription<dynamic> subscription, {
    FutureOr<void> Function()? onCancel,
    String owner = 'RaceSimulationScreen',
    String? label,
  }) {
    final String normalizedId = _normalizeId(id);
    _records[normalizedId] = _TrackedResourceRecord(
      entry: TrackedResourceEntry(
        id: normalizedId,
        kind: LeakResourceKind.streamSubscription,
        owner: owner,
        label: label ?? normalizedId,
        registeredAt: DateTime.now(),
        status: LeakResourceStatus.active,
        sessionId: _activeSessionId,
      ),
      streamSubscription: subscription,
      onStreamCancel: onCancel,
    );
    _emitSnapshot();
  }

  /// Oznacza [StreamSubscription] jako poprawnie anulowaną przez `cancel()`.
  void markStreamSubscriptionCancelled(String id) {
    _markDisposed(id, expectedKind: LeakResourceKind.streamSubscription);
  }

  /// Kończy sesję wyścigu 3D (powrót do widoku menedżera) i przeprowadza audyt.
  ///
  /// Jeśli [autoCleanupLeaks] ma wartość `true`, wykryte wycieki są od razu
  /// bezpiecznie zamykane (`Isolate.kill`, `AnimationController.dispose`,
  /// `StreamSubscription.cancel`), a w raporcie oznaczane jako wyczyszczone.
  Future<LeakAuditReport> endRace3dSessionAndAudit({
    bool autoCleanupLeaks = false,
  }) async {
    final String sessionId = _activeSessionId ?? 'untracked_session';
    final String? stageName = _activeStageName;
    final int? rssBefore = _sessionStartRssBytes;

    int leakedIsolates = 0;
    int leakedControllers = 0;
    int leakedSubscriptions = 0;
    int properlyDisposed = 0;
    int forceCleanedCount = 0;
    final List<LeakAuditIssue> issues = <LeakAuditIssue>[];

    final List<_TrackedResourceRecord> sessionRecords = _records.values
        .where(
          (record) =>
              _activeSessionId == null ||
              record.entry.sessionId == _activeSessionId,
        )
        .toList();

    for (final _TrackedResourceRecord record in sessionRecords) {
      if (record.entry.status == LeakResourceStatus.disposed) {
        properlyDisposed += 1;
        continue;
      }
      if (record.entry.status == LeakResourceStatus.forceCleaned) {
        forceCleanedCount += 1;
        continue;
      }

      switch (record.entry.kind) {
        case LeakResourceKind.isolate:
          leakedIsolates += 1;
          break;
        case LeakResourceKind.animationController:
          leakedControllers += 1;
          break;
        case LeakResourceKind.streamSubscription:
          leakedSubscriptions += 1;
          break;
      }

      bool cleaned = false;
      if (autoCleanupLeaks) {
        cleaned = await _forceCleanRecord(record);
        if (cleaned) {
          forceCleanedCount += 1;
        }
      } else {
        record.entry = record.entry.copyWith(
          status: LeakResourceStatus.leaked,
          notes: 'Zasób pozostał otwarty po wyjściu z wyścigu 3D.',
        );
      }

      issues.add(
        LeakAuditIssue(
          resourceId: record.entry.id,
          kind: record.entry.kind,
          owner: record.entry.owner,
          message:
              '${record.entry.kind.label} "${record.entry.label}" (${record.entry.owner}) nie został zamknięty przy powrocie do widoku menedżera.',
          wasForceCleaned: cleaned,
        ),
      );
    }

    final int? rssAfter = _tryReadProcessRssBytes();
    final LeakAuditReport report = LeakAuditReport(
      sessionId: sessionId,
      stageName: stageName,
      auditedAt: DateTime.now(),
      totalTracked: sessionRecords.length,
      properlyDisposed: properlyDisposed,
      leakedIsolates: leakedIsolates,
      leakedAnimationControllers: leakedControllers,
      leakedStreamSubscriptions: leakedSubscriptions,
      forceCleanedCount: forceCleanedCount,
      rssBytesBeforeExit: rssBefore,
      rssBytesAfterExit: rssAfter,
      issues: List<LeakAuditIssue>.unmodifiable(issues),
    );

    _activeSessionId = null;
    _activeStageName = null;
    _sessionStartRssBytes = null;
    _lastAuditReport = report;

    if (!_isGuardDisposed && !_auditReportController.isClosed) {
      _auditReportController.add(report);
    }
    _emitSnapshot();
    return report;
  }

  /// Awaryjnie zamyka wszystkie aktywne lub wyciekłe zasoby śledzone przez strażnika.
  Future<int> cleanupLeakedResources() async {
    int cleaned = 0;
    for (final _TrackedResourceRecord record in _records.values) {
      if (record.entry.status == LeakResourceStatus.active ||
          record.entry.status == LeakResourceStatus.leaked) {
        final bool success = await _forceCleanRecord(record);
        if (success) {
          cleaned += 1;
        }
      }
    }
    _emitSnapshot();
    return cleaned;
  }

  /// Czyści historię wpisów i resetuje stan bieżącej sesji.
  void reset() {
    _records.clear();
    _activeSessionId = null;
    _activeStageName = null;
    _sessionStartRssBytes = null;
    _lastAuditReport = null;
    _emitSnapshot();
  }

  /// Zwalnia wewnętrzne strumienie instancji (np. po zakończeniu testów jednostkowych).
  Future<void> disposeGuard() async {
    if (_isGuardDisposed) {
      return;
    }
    _isGuardDisposed = true;
    await cleanupLeakedResources();
    _records.clear();
    snapshotNotifier.dispose();
    if (!_auditReportController.isClosed) {
      await _auditReportController.close();
    }
  }

  void _markDisposed(
    String id, {
    required LeakResourceKind expectedKind,
  }) {
    final String normalizedId = _normalizeId(id);
    final _TrackedResourceRecord? record = _records[normalizedId];
    if (record == null || record.entry.kind != expectedKind) {
      return;
    }
    if (record.entry.status == LeakResourceStatus.disposed ||
        record.entry.status == LeakResourceStatus.forceCleaned) {
      return;
    }
    record.entry = record.entry.copyWith(
      status: LeakResourceStatus.disposed,
      disposedAt: DateTime.now(),
      notes: 'Zamknięty poprawnie.',
    );
    record.isolate = null;
    record.onIsolateDispose = null;
    record.animationController = null;
    record.streamSubscription = null;
    record.onStreamCancel = null;
    _emitSnapshot();
  }

  Future<bool> _forceCleanRecord(_TrackedResourceRecord record) async {
    try {
      switch (record.entry.kind) {
        case LeakResourceKind.isolate:
          if (record.onIsolateDispose != null) {
            await record.onIsolateDispose!.call();
          }
          record.isolate?.kill(priority: Isolate.immediate);
          record.isolate = null;
          record.onIsolateDispose = null;
          break;
        case LeakResourceKind.animationController:
          final AnimationController? controller = record.animationController;
          if (controller != null) {
            try {
              if (controller.isAnimating) {
                controller.stop(canceled: true);
              }
              controller.dispose();
            } catch (_) {
              // Kontroler mógł zostać zwolniony bezpośrednio poza strażnikiem.
            }
          }
          record.animationController = null;
          break;
        case LeakResourceKind.streamSubscription:
          if (record.onStreamCancel != null) {
            await record.onStreamCancel!.call();
          }
          await record.streamSubscription?.cancel();
          record.streamSubscription = null;
          record.onStreamCancel = null;
          break;
      }

      record.entry = record.entry.copyWith(
        status: LeakResourceStatus.forceCleaned,
        disposedAt: DateTime.now(),
        notes: 'Zamknięty awaryjnie przez MemoryAndStreamLeakGuard.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  void _emitSnapshot() {
    if (_isGuardDisposed) {
      return;
    }
    int activeIsolates = 0;
    int activeControllers = 0;
    int activeSubscriptions = 0;
    int disposedCount = 0;
    int forceCleanedCount = 0;

    for (final _TrackedResourceRecord record in _records.values) {
      switch (record.entry.status) {
        case LeakResourceStatus.active:
        case LeakResourceStatus.leaked:
          switch (record.entry.kind) {
            case LeakResourceKind.isolate:
              activeIsolates += 1;
              break;
            case LeakResourceKind.animationController:
              activeControllers += 1;
              break;
            case LeakResourceKind.streamSubscription:
              activeSubscriptions += 1;
              break;
          }
          break;
        case LeakResourceStatus.disposed:
          disposedCount += 1;
          break;
        case LeakResourceStatus.forceCleaned:
          forceCleanedCount += 1;
          break;
      }
    }

    snapshotNotifier.value = LeakGuardSnapshot(
      isRace3dSessionActive: _activeSessionId != null,
      activeSessionId: _activeSessionId,
      activeStageName: _activeStageName,
      activeIsolatesCount: activeIsolates,
      activeAnimationControllersCount: activeControllers,
      activeStreamSubscriptionsCount: activeSubscriptions,
      totalDisposedInSession: disposedCount,
      totalForceCleanedInSession: forceCleanedCount,
      entries: List<TrackedResourceEntry>.unmodifiable(
        _records.values.map((r) => r.entry),
      ),
      lastAuditReport: _lastAuditReport,
    );
  }

  String _normalizeId(String id) {
    final String trimmed = id.trim();
    if (trimmed.isEmpty) {
      return 'unnamed_resource_${_records.length + 1}';
    }
    return trimmed;
  }

  int? _tryReadProcessRssBytes() {
    try {
      return ProcessInfo.currentRss;
    } catch (_) {
      return null;
    }
  }
}

/// Globalny provider Riverpod udostępniający [MemoryAndStreamLeakGuard].
final memoryAndStreamLeakGuardProvider = Provider<MemoryAndStreamLeakGuard>(
  (ref) => MemoryAndStreamLeakGuard.instance,
);

/// Responsywny panel diagnostyczny strażnika pamięci [MemoryAndStreamLeakGuard].
///
/// Dostosowuje układ do rozdzielczości `390x844` (mobile), `1024x768` (tablet)
/// oraz `1600x900` (desktop) zgodnie z paletą [AppColors] i typografią `Inter`.
class MemoryAndStreamLeakGuardPanel extends StatefulWidget {
  final MemoryAndStreamLeakGuard? guard;
  final VoidCallback? onAuditCompleted;

  const MemoryAndStreamLeakGuardPanel({
    super.key,
    this.guard,
    this.onAuditCompleted,
  });

  @override
  State<MemoryAndStreamLeakGuardPanel> createState() =>
      _MemoryAndStreamLeakGuardPanelState();
}

class _MemoryAndStreamLeakGuardPanelState
    extends State<MemoryAndStreamLeakGuardPanel>
    with SingleTickerProviderStateMixin {
  LeakResourceKind? _selectedFilter;
  bool _isProcessingAction = false;
  late final AnimationController _pulseController;

  MemoryAndStreamLeakGuard get _guard =>
      widget.guard ?? MemoryAndStreamLeakGuard.instance;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAuditPressed() async {
    if (_isProcessingAction) {
      return;
    }
    setState(() => _isProcessingAction = true);
    try {
      await _guard.endRace3dSessionAndAudit(autoCleanupLeaks: false);
      widget.onAuditCompleted?.call();
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  Future<void> _handleCleanupPressed() async {
    if (_isProcessingAction) {
      return;
    }
    setState(() => _isProcessingAction = true);
    try {
      await _guard.cleanupLeakedResources();
    } finally {
      if (mounted) {
        setState(() => _isProcessingAction = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LeakGuardSnapshot>(
      valueListenable: _guard.snapshotNotifier,
      builder: (BuildContext context, LeakGuardSnapshot snapshot, _) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 600;
            final bool isWide = constraints.maxWidth >= 1000;
            final List<TrackedResourceEntry> filteredEntries = snapshot.entries
                .where(
                  (entry) =>
                      _selectedFilter == null || entry.kind == _selectedFilter,
                )
                .toList();

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor, width: 1),
              ),
              padding: EdgeInsets.all(isCompact ? 14 : 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildHeader(snapshot, isCompact),
                  const SizedBox(height: 14),
                  _buildMetricsGrid(snapshot, isCompact, isWide),
                  if (snapshot.lastAuditReport != null) ...<Widget>[
                    const SizedBox(height: 14),
                    _buildAuditBanner(snapshot.lastAuditReport!, isCompact),
                  ],
                  const SizedBox(height: 14),
                  _buildFilterRow(snapshot, isCompact),
                  const SizedBox(height: 12),
                  _buildEntriesList(filteredEntries, isCompact),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(LeakGuardSnapshot snapshot, bool isCompact) {
    final bool hasLeaks = snapshot.leakedCount > 0;
    final Color statusColor = hasLeaks
        ? AppColors.crimsonAlert
        : (snapshot.isRace3dSessionActive
            ? AppColors.amberWarning
            : AppColors.statusSuccess);

    final Widget titleBlock = Row(
      children: <Widget>[
        FadeTransition(
          opacity: Tween<double>(begin: 0.45, end: 1.0).animate(
            CurvedAnimation(
              parent: _pulseController,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Strażnik Pamięci i Strumieni 3D',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                snapshot.isRace3dSessionActive
                    ? 'Aktywna sesja: ${snapshot.activeStageName ?? snapshot.activeSessionId}'
                    : 'Widok menedżera — gotowy do audytu wyjścia 3D',
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

    final bool canAudit =
        !_isProcessingAction &&
        (snapshot.isRace3dSessionActive || snapshot.totalActiveCount > 0);
    final bool canCleanup =
        !_isProcessingAction &&
        (snapshot.totalActiveCount > 0 || snapshot.leakedCount > 0);

    final Widget actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        _InteractiveGuardButton(
          label: 'Audyt Wyjścia 3D',
          icon: Icons.verified_user_outlined,
          isPrimary: true,
          enabled: canAudit,
          onPressed: _handleAuditPressed,
        ),
        _InteractiveGuardButton(
          label: 'Wyczyść Wycieki',
          icon: Icons.cleaning_services_rounded,
          isPrimary: false,
          enabled: canCleanup,
          onPressed: _handleCleanupPressed,
        ),
      ],
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          titleBlock,
          const SizedBox(height: 12),
          actions,
        ],
      );
    }

    return Row(
      children: <Widget>[
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _buildMetricsGrid(
    LeakGuardSnapshot snapshot,
    bool isCompact,
    bool isWide,
  ) {
    final List<Widget> cards = <Widget>[
      _MetricTile(
        label: 'Isolate',
        value: snapshot.activeIsolatesCount.toString(),
        icon: Icons.memory_rounded,
        accentColor: snapshot.activeIsolatesCount > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
      ),
      _MetricTile(
        label: 'AnimationController',
        value: snapshot.activeAnimationControllersCount.toString(),
        icon: Icons.animation_rounded,
        accentColor: snapshot.activeAnimationControllersCount > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
      ),
      _MetricTile(
        label: 'StreamSubscription',
        value: snapshot.activeStreamSubscriptionsCount.toString(),
        icon: Icons.stream_rounded,
        accentColor: snapshot.activeStreamSubscriptionsCount > 0
            ? AppColors.amberWarning
            : AppColors.statusSuccess,
      ),
      _MetricTile(
        label: 'Zamknięte / Wycieki',
        value: '${snapshot.totalDisposedInSession} / ${snapshot.leakedCount}',
        icon: Icons.shield_outlined,
        accentColor: snapshot.leakedCount > 0
            ? AppColors.crimsonAlert
            : AppColors.accentBlue,
      ),
    ];

    final int columns = isWide ? 4 : (isCompact ? 2 : 4);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        const double spacing = 10;
        final double itemWidth =
            (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth > 0 ? itemWidth : box.maxWidth,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAuditBanner(LeakAuditReport report, bool isCompact) {
    final bool clean = report.isClean;
    final Color bannerColor =
        clean ? AppColors.statusSuccess : AppColors.crimsonAlert;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(isCompact ? 10 : 12),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            clean ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: bannerColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              clean
                  ? 'Audyt wyjścia 3D czysty (${report.properlyDisposed}/${report.totalTracked} zasobów zamkniętych).'
                  : 'Wykryto ${report.totalLeaked} wycieków przy wyjściu z 3D (Isolate: ${report.leakedIsolates}, Anim: ${report.leakedAnimationControllers}, Stream: ${report.leakedStreamSubscriptions}).',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(LeakGuardSnapshot snapshot, bool isCompact) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _FilterChipButton(
            label: 'Wszystkie (${snapshot.entries.length})',
            selected: _selectedFilter == null,
            onTap: () => setState(() => _selectedFilter = null),
          ),
          const SizedBox(width: 8),
          for (final LeakResourceKind kind in LeakResourceKind.values) ...<Widget>[
            _FilterChipButton(
              label:
                  '${kind.label} (${snapshot.entries.where((e) => e.kind == kind).length})',
              selected: _selectedFilter == kind,
              onTap: () => setState(() => _selectedFilter = kind),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildEntriesList(
    List<TrackedResourceEntry> entries,
    bool isCompact,
  ) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: const Center(
          child: Text(
            'Brak zarejestrowanych zasobów w wybranym filtrze.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (BuildContext context, int index) {
          final TrackedResourceEntry entry = entries[index];
          final Color badgeColor = _statusColor(entry.status);
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 10 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder, width: 1),
            ),
            child: Row(
              children: <Widget>[
                Icon(entry.kind.icon, size: 16, color: AppColors.goldAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entry.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${entry.kind.label} • ${entry.owner}',
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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: badgeColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    entry.status.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _statusColor(LeakResourceStatus status) {
    switch (status) {
      case LeakResourceStatus.active:
        return AppColors.amberWarning;
      case LeakResourceStatus.disposed:
        return AppColors.statusSuccess;
      case LeakResourceStatus.leaked:
        return AppColors.crimsonAlert;
      case LeakResourceStatus.forceCleaned:
        return AppColors.accentBlue;
    }
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: accentColor,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveGuardButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final bool enabled;
  final VoidCallback onPressed;

  const _InteractiveGuardButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.enabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveGuardButton> createState() =>
      _InteractiveGuardButtonState();
}

class _InteractiveGuardButtonState extends State<_InteractiveGuardButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final Color bgColor = !widget.enabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : (_pressed
            ? baseBg.withValues(alpha: 0.8)
            : (_hovered ? baseBg.withValues(alpha: 0.92) : baseBg));
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (!widget.enabled
            ? AppColors.cardBorder.withValues(alpha: 0.4)
            : (_hovered ? AppColors.goldAccent : AppTheme.borderColor));
    final Color fgColor = widget.enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary.withValues(alpha: 0.55);

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowFocusHighlight: (bool value) => setState(() => _focused = value),
      onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          onTapDown: widget.enabled
              ? (_) => setState(() => _pressed = true)
              : null,
          onTapUp: widget.enabled
              ? (_) => setState(() => _pressed = false)
              : null,
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
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
      ),
    );
  }
}

class _FilterChipButton extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_FilterChipButton> createState() => _FilterChipButtonState();
}

class _FilterChipButtonState extends State<_FilterChipButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor = widget.selected
        ? AppColors.goldAccent.withValues(alpha: 0.18)
        : (_hovered ? AppColors.surfaceLight : AppColors.background);
    final Color borderColor = _focused
        ? AppColors.goldAccent
        : (widget.selected
            ? AppColors.goldAccent
            : (_hovered ? AppColors.textSecondary : AppColors.cardBorder));

    return FocusableActionDetector(
      onShowFocusHighlight: (bool value) => setState(() => _focused = value),
      onShowHoverHighlight: (bool value) => setState(() => _hovered = value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                color: widget.selected
                    ? AppColors.goldAccent
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
