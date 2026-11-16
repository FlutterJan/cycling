import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Zstrukturyzowany raport błędu UI używany przez [GlobalErrorBoundaryWidget]
/// do prezentacji diagnostyki oraz eksportu logu.
class DiagnosticErrorReport {
  const DiagnosticErrorReport({
    required this.timestamp,
    required this.exceptionType,
    required this.message,
    required this.stackTrace,
    required this.platform,
    this.library,
    this.contextDescription,
  });

  /// Tworzy raport na podstawie obiektu [FlutterErrorDetails].
  factory DiagnosticErrorReport.fromFlutterError(FlutterErrorDetails details) {
    final exception = details.exception;
    final rawMessage = details.exceptionAsString().trim();
    final stack = details.stack?.toString().trim() ?? '';

    return DiagnosticErrorReport(
      timestamp: DateTime.now().toUtc(),
      exceptionType: exception.runtimeType.toString(),
      message: rawMessage.isEmpty ? 'Nieznany błąd renderowania UI.' : rawMessage,
      stackTrace: stack.isEmpty ? 'Brak śladu stosu (StackTrace).' : stack,
      platform: defaultTargetPlatform.name,
      library: details.library,
      contextDescription: details.context?.toDescription(),
    );
  }

  /// Tworzy raport na podstawie dowolnego wyjątku i opcjonalnego [StackTrace].
  factory DiagnosticErrorReport.fromObject(
    Object error, [
    StackTrace? stackTrace,
  ]) {
    final rawMessage = error.toString().trim();
    final stack = stackTrace?.toString().trim() ?? '';

    return DiagnosticErrorReport(
      timestamp: DateTime.now().toUtc(),
      exceptionType: error.runtimeType.toString(),
      message: rawMessage.isEmpty ? 'Nieznany błąd aplikacji.' : rawMessage,
      stackTrace: stack.isEmpty ? 'Brak śladu stosu (StackTrace).' : stack,
      platform: defaultTargetPlatform.name,
    );
  }

  final DateTime timestamp;
  final String exceptionType;
  final String message;
  final String stackTrace;
  final String platform;
  final String? library;
  final String? contextDescription;

  /// Formatuje raport jako czytelny plik tekstowy gotowy do zapisu lub schowka.
  String toFormattedLog() {
    final buffer = StringBuffer()
      ..writeln('=== PRO PELOTON MANAGER — DIAGNOSTIC ERROR REPORT ===')
      ..writeln('Timestamp (UTC): ${timestamp.toIso8601String()}')
      ..writeln('Platform: $platform')
      ..writeln('Exception Type: $exceptionType');

    if (library != null && library!.trim().isNotEmpty) {
      buffer.writeln('Library: ${library!.trim()}');
    }
    if (contextDescription != null && contextDescription!.trim().isNotEmpty) {
      buffer.writeln('Context: ${contextDescription!.trim()}');
    }

    buffer
      ..writeln('')
      ..writeln('--- Message ---')
      ..writeln(message)
      ..writeln('')
      ..writeln('--- Stack Trace ---')
      ..writeln(stackTrace)
      ..writeln('=====================================================');

    return buffer.toString();
  }

  /// Serializuje raport do mapy JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'timestampUtc': timestamp.toIso8601String(),
        'platform': platform,
        'exceptionType': exceptionType,
        'library': library,
        'contextDescription': contextDescription,
        'message': message,
        'stackTrace': stackTrace,
      };

  /// Zwraca sformatowany ciąg JSON raportu.
  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

enum _ExportStatus {
  idle,
  exporting,
  exported,
  failed,
}

/// Produkcyjna granica błędów UI zastępująca domyślny czerwony ekran błędu
/// Fluttera ciemnym panelem diagnostycznym z opcją powrotu do Dashboardu
/// oraz eksportu raportu diagnostycznego.
class GlobalErrorBoundaryWidget extends StatefulWidget {
  const GlobalErrorBoundaryWidget({
    super.key,
    this.errorDetails,
    this.error,
    this.stackTrace,
    this.onReturnToDashboard,
    this.onExportLog,
    this.onRetry,
    this.dashboardRoute = AppRoutes.dashboard,
    this.initiallyExpandedStackTrace = false,
  });

  final FlutterErrorDetails? errorDetails;
  final Object? error;
  final StackTrace? stackTrace;
  final VoidCallback? onReturnToDashboard;
  final Future<bool> Function(DiagnosticErrorReport report)? onExportLog;
  final VoidCallback? onRetry;
  final String dashboardRoute;
  final bool initiallyExpandedStackTrace;

  static ErrorWidgetBuilder? _previousBuilder;

  /// Rejestruje [GlobalErrorBoundaryWidget] jako globalny [ErrorWidget.builder].
  static void install({
    VoidCallback? onReturnToDashboard,
    Future<bool> Function(DiagnosticErrorReport report)? onExportLog,
    String dashboardRoute = AppRoutes.dashboard,
  }) {
    _previousBuilder ??= ErrorWidget.builder;
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return GlobalErrorBoundaryWidget(
        errorDetails: details,
        onReturnToDashboard: onReturnToDashboard,
        onExportLog: onExportLog,
        dashboardRoute: dashboardRoute,
      );
    };
  }

  /// Przywraca poprzedni [ErrorWidget.builder] (np. na potrzeby testów).
  static void restoreDefaultErrorWidget() {
    if (_previousBuilder != null) {
      ErrorWidget.builder = _previousBuilder!;
      _previousBuilder = null;
    }
  }

  @override
  State<GlobalErrorBoundaryWidget> createState() =>
      _GlobalErrorBoundaryWidgetState();
}

class _GlobalErrorBoundaryWidgetState extends State<GlobalErrorBoundaryWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late DiagnosticErrorReport _report;

  bool _isStackExpanded = false;
  bool _isNavigating = false;
  _ExportStatus _exportStatus = _ExportStatus.idle;
  Timer? _exportResetTimer;

  @override
  void initState() {
    super.initState();
    _isStackExpanded = widget.initiallyExpandedStackTrace;
    _report = _buildReport();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: Curves.easeOutCubic,
      ),
    );
    _entryController.forward();
  }

  @override
  void didUpdateWidget(covariant GlobalErrorBoundaryWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.errorDetails != widget.errorDetails ||
        oldWidget.error != widget.error ||
        oldWidget.stackTrace != widget.stackTrace) {
      _report = _buildReport();
      _exportStatus = _ExportStatus.idle;
    }
  }

  @override
  void dispose() {
    _exportResetTimer?.cancel();
    _entryController.dispose();
    super.dispose();
  }

  DiagnosticErrorReport _buildReport() {
    if (widget.errorDetails != null) {
      return DiagnosticErrorReport.fromFlutterError(widget.errorDetails!);
    }
    if (widget.error != null) {
      return DiagnosticErrorReport.fromObject(widget.error!, widget.stackTrace);
    }
    return DiagnosticErrorReport.fromObject(
      StateError('Nieoczekiwany błąd warstwy prezentacji UI.'),
      widget.stackTrace,
    );
  }

  Future<void> _handleExportLog() async {
    if (_exportStatus == _ExportStatus.exporting) {
      return;
    }

    _exportResetTimer?.cancel();
    setState(() {
      _exportStatus = _ExportStatus.exporting;
    });

    bool success = false;
    try {
      if (widget.onExportLog != null) {
        success = await widget.onExportLog!(_report);
      } else {
        await Clipboard.setData(
          ClipboardData(text: _report.toFormattedLog()),
        );
        success = true;
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _exportStatus = success ? _ExportStatus.exported : _ExportStatus.failed;
    });

    _exportResetTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _exportStatus = _ExportStatus.idle;
        });
      }
    });
  }

  void _handleReturnToDashboard() {
    if (_isNavigating) {
      return;
    }

    setState(() {
      _isNavigating = true;
    });

    try {
      if (widget.onReturnToDashboard != null) {
        widget.onReturnToDashboard!();
        return;
      }

      final goRouter = GoRouter.maybeOf(context);
      if (goRouter != null) {
        goRouter.go(widget.dashboardRoute);
        return;
      }

      final navigator = Navigator.maybeOf(context);
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  String _formatTimestamp(DateTime utc) {
    final local = utc.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDirectionality = Directionality.maybeOf(context) != null;

    final content = Material(
      color: AppColors.background,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final isCompact = constraints.maxWidth < 560;
            final isTablet =
                constraints.maxWidth >= 560 && constraints.maxWidth < 1100;
            final horizontalPadding = isCompact ? 16.0 : (isTablet ? 28.0 : 40.0);
            final maxCardWidth = isCompact ? double.infinity : 860.0;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: isCompact ? 16.0 : 28.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxCardWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildDiagnosticPanel(isCompact: isCompact),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (hasDirectionality) {
      return content;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: content,
    );
  }

  Widget _buildDiagnosticPanel({required bool isCompact}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderColor,
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.all(isCompact ? 18.0 : 28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(isCompact: isCompact),
          const SizedBox(height: 20),
          _buildErrorSummaryCard(isCompact: isCompact),
          const SizedBox(height: 16),
          _buildStackTraceSection(),
          const SizedBox(height: 22),
          _buildActionBar(isCompact: isCompact),
        ],
      ),
    );
  }

  Widget _buildHeader({required bool isCompact}) {
    final badge = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.crimsonAlert.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.crimsonAlert.withValues(alpha: 0.45),
          width: 1.0,
        ),
      ),
      child: const Icon(
        Icons.warning_amber_rounded,
        color: AppColors.crimsonAlert,
        size: 24,
      ),
    );

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Text(
                'DIAGNOSTYKA INTERFEJSU • RACE CONTROL',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: AppColors.goldAccent.withValues(alpha: 0.95),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Wykryto nieoczekiwany błąd renderowania',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: isCompact ? 18 : 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Granica błędów odizolowała awarię widoku, aby chronić stan kariery i symulacji.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            height: 1.4,
            letterSpacing: -0.2,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );

    final timestampPill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.schedule_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            _formatTimestamp(_report.timestamp),
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              badge,
              const SizedBox(width: 12),
              Expanded(child: titleColumn),
            ],
          ),
          const SizedBox(height: 12),
          timestampPill,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        badge,
        const SizedBox(width: 16),
        Expanded(child: titleColumn),
        const SizedBox(width: 16),
        timestampPill,
      ],
    );
  }

  Widget _buildErrorSummaryCard({required bool isCompact}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _MetadataChip(
                label: _report.exceptionType,
                accentColor: AppColors.crimsonAlert,
              ),
              _MetadataChip(
                label: 'Platforma: ${_report.platform}',
                accentColor: AppColors.accentBlue,
              ),
              if (_report.library != null && _report.library!.trim().isNotEmpty)
                _MetadataChip(
                  label: _report.library!.trim(),
                  accentColor: AppColors.goldAccent,
                ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            _report.message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.45,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
              color: AppColors.textPrimary,
            ),
          ),
          if (_report.contextDescription != null &&
              _report.contextDescription!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              'Kontekst: ${_report.contextDescription!.trim()}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStackTraceSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _BoundaryActionButton(
            onPressed: () {
              setState(() {
                _isStackExpanded = !_isStackExpanded;
              });
            },
            backgroundColor: AppColors.background,
            hoverColor: AppColors.surfaceLight,
            borderColor: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.terminal_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Szczegóły techniczne i Stack Trace',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isStackExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  child: const Icon(
                    Icons.expand_more_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _isStackExpanded
                ? Container(
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppTheme.borderColor, width: 1.0),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(14),
                      child: SelectableText(
                        _report.stackTrace,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          height: 1.5,
                          color: AppColors.textSecondary,
                          fontFeatures: <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar({required bool isCompact}) {
    final exportLabel = switch (_exportStatus) {
      _ExportStatus.idle => 'Eksportuj log',
      _ExportStatus.exporting => 'Eksportowanie...',
      _ExportStatus.exported => 'Log skopiowano',
      _ExportStatus.failed => 'Błąd eksportu',
    };

    final exportIcon = switch (_exportStatus) {
      _ExportStatus.idle => Icons.ios_share_rounded,
      _ExportStatus.exporting => Icons.hourglass_top_rounded,
      _ExportStatus.exported => Icons.check_circle_outline_rounded,
      _ExportStatus.failed => Icons.error_outline_rounded,
    };

    final exportBorderColor = switch (_exportStatus) {
      _ExportStatus.exported => AppColors.statusSuccess,
      _ExportStatus.failed => AppColors.crimsonAlert,
      _ => AppTheme.borderColor,
    };

    final exportTextColor = switch (_exportStatus) {
      _ExportStatus.exported => AppColors.statusSuccess,
      _ExportStatus.failed => AppColors.crimsonAlert,
      _ => AppColors.textPrimary,
    };

    final returnButton = _BoundaryActionButton(
      key: const Key('error_boundary_dashboard_button'),
      onPressed: _isNavigating ? null : _handleReturnToDashboard,
      backgroundColor: AppColors.primaryAccent,
      hoverColor: const Color(0xFFA25756),
      borderColor: AppColors.goldAccent.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.dashboard_rounded,
            size: 18,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isNavigating ? 'Powrót...' : 'Powrót do Dashboardu',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final exportButton = _BoundaryActionButton(
      key: const Key('error_boundary_export_button'),
      onPressed:
          _exportStatus == _ExportStatus.exporting ? null : _handleExportLog,
      backgroundColor: AppColors.surfaceLight,
      hoverColor: const Color(0xFF2B303D),
      borderColor: exportBorderColor,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            exportIcon,
            size: 18,
            color: exportTextColor,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              exportLabel,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: exportTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final retryButton = widget.onRetry == null
        ? null
        : _BoundaryActionButton(
            key: const Key('error_boundary_retry_button'),
            onPressed: widget.onRetry,
            backgroundColor: AppColors.background,
            hoverColor: AppColors.surfaceLight,
            borderColor: AppTheme.borderColor,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 8),
                Text(
                  'Spróbuj ponownie',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          returnButton,
          const SizedBox(height: 10),
          exportButton,
          if (retryButton != null) ...<Widget>[
            const SizedBox(height: 10),
            retryButton,
          ],
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 10,
      children: <Widget>[
        if (retryButton != null) retryButton,
        exportButton,
        returnButton,
      ],
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.label,
    required this.accentColor,
  });

  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
          color: accentColor,
        ),
      ),
    );
  }
}

class _BoundaryActionButton extends StatefulWidget {
  const _BoundaryActionButton({
    super.key,
    required this.onPressed,
    required this.backgroundColor,
    required this.hoverColor,
    required this.borderColor,
    required this.borderRadius,
    required this.padding,
    required this.child,
  });

  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color hoverColor;
  final Color borderColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  State<_BoundaryActionButton> createState() => _BoundaryActionButtonState();
}

class _BoundaryActionButtonState extends State<_BoundaryActionButton> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  bool get _isEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = !_isEnabled
        ? widget.backgroundColor.withValues(alpha: 0.45)
        : (_isHovered ? widget.hoverColor : widget.backgroundColor);

    final effectiveBorder = _isFocused
        ? AppColors.goldAccent
        : (!_isEnabled
            ? widget.borderColor.withValues(alpha: 0.45)
            : widget.borderColor);

    return FocusableActionDetector(
      enabled: _isEnabled,
      onShowFocusHighlight: (focused) {
        if (mounted) {
          setState(() => _isFocused = focused);
        }
      },
      onShowHoverHighlight: (hovered) {
        if (mounted) {
          setState(() => _isHovered = hovered);
        }
      },
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed?.call();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: _isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _isEnabled ? widget.onPressed : null,
          onTapDown: _isEnabled
              ? (_) => setState(() => _isPressed = true)
              : null,
          onTapUp: _isEnabled
              ? (_) => setState(() => _isPressed = false)
              : null,
          onTapCancel: _isEnabled
              ? () => setState(() => _isPressed = false)
              : null,
          child: AnimatedScale(
            scale: _isPressed && _isEnabled ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: _isEnabled ? 1.0 : 0.55,
              duration: const Duration(milliseconds: 200),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: widget.padding,
                decoration: BoxDecoration(
                  color: effectiveBg,
                  borderRadius: widget.borderRadius,
                  border: Border.all(
                    color: effectiveBorder,
                    width: _isFocused ? 1.5 : 1.0,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
