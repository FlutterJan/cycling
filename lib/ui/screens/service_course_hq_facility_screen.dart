import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../services/career/team_service_course_hq_upgrades.dart';

/// Ekran zarządzania infrastrukturą klubu (`Service Course HQ`).
///
/// Prezentuje interaktywną wizualizację 5 działów Service Course, poziomy
/// rozbudowy (Poziom 1–5), koszty utrzymania (roczne i miesięczne) oraz
/// czas trwania i postęp inwestycji budowlanych.
class ServiceCourseHqFacilityScreen extends ConsumerStatefulWidget {
  const ServiceCourseHqFacilityScreen({
    super.key,
    this.initialState,
    this.onStateChanged,
    this.showAppBar = true,
  });

  /// Opcjonalny stan początkowy (używany np. w testach lub podglądach).
  /// Gdy `null`, ekran korzysta bezpośrednio z [teamServiceCourseHqProvider].
  final TeamServiceCourseHqState? initialState;

  /// Callback wywoływany po każdej zmianie stanu infrastruktury.
  final ValueChanged<TeamServiceCourseHqState>? onStateChanged;

  /// Czy wyświetlać górny pasek nawigacji [AppBar].
  final bool showAppBar;

  @override
  ConsumerState<ServiceCourseHqFacilityScreen> createState() =>
      _ServiceCourseHqFacilityScreenState();
}

class _ServiceCourseHqFacilityScreenState
    extends ConsumerState<ServiceCourseHqFacilityScreen> {
  TeamServiceCourseHqState? _localState;
  ServiceCourseModuleId _selectedModuleId = ServiceCourseModuleId.windTunnel;
  String? _statusMessage;
  bool _statusIsError = false;

  bool get _usesLocalState => widget.initialState != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialState != null) {
      _localState = widget.initialState;
    }
  }

  @override
  void didUpdateWidget(covariant ServiceCourseHqFacilityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialState != null &&
        widget.initialState != oldWidget.initialState) {
      _localState = widget.initialState;
    }
  }

  TeamServiceCourseHqState _currentState() {
    if (_usesLocalState) {
      return _localState!;
    }
    return ref.watch(teamServiceCourseHqProvider);
  }

  void _handleStartUpgrade(ServiceCourseModuleId moduleId) {
    final ServiceCourseUpgradeResult result;
    if (_usesLocalState) {
      result = TeamServiceCourseHqUpgrades.startUpgrade(
        _localState!,
        moduleId,
      );
      if (result.success) {
        setState(() {
          _localState = result.state;
        });
        widget.onStateChanged?.call(result.state);
      }
    } else {
      result = ref
          .read(teamServiceCourseHqProvider.notifier)
          .startUpgrade(moduleId);
      if (result.success) {
        widget.onStateChanged?.call(result.state);
      }
    }

    setState(() {
      _statusMessage = result.message;
      _statusIsError = !result.success;
    });
  }

  void _handleCancelConstruction(ServiceCourseModuleId moduleId) {
    final ServiceCourseUpgradeResult result;
    if (_usesLocalState) {
      result = TeamServiceCourseHqUpgrades.cancelConstruction(
        _localState!,
        moduleId,
      );
      if (result.success) {
        setState(() {
          _localState = result.state;
        });
        widget.onStateChanged?.call(result.state);
      }
    } else {
      result = ref
          .read(teamServiceCourseHqProvider.notifier)
          .cancelConstruction(moduleId);
      if (result.success) {
        widget.onStateChanged?.call(result.state);
      }
    }

    setState(() {
      _statusMessage = result.message;
      _statusIsError = !result.success;
    });
  }

  void _handleAdvanceDays(int days) {
    if (days <= 0) return;
    if (_usesLocalState) {
      final next = TeamServiceCourseHqUpgrades.advanceConstructionDays(
        _localState!,
        days,
      );
      setState(() {
        _localState = next;
        _statusMessage = 'Symulowano postęp prac budowlanych o +$days dni.';
        _statusIsError = false;
      });
      widget.onStateChanged?.call(next);
    } else {
      ref.read(teamServiceCourseHqProvider.notifier).advanceDays(days);
      final next = ref.read(teamServiceCourseHqProvider);
      setState(() {
        _statusMessage = 'Symulowano postęp prac budowlanych o +$days dni.';
        _statusIsError = false;
      });
      widget.onStateChanged?.call(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentState();
    final bonuses = state.bonuses;
    final monthlyUpkeepEur =
        TeamServiceCourseHqUpgrades.calculateMonthlyUpkeepEur(state);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              titleSpacing: 20,
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Icon(
                      Icons.corporate_fare_rounded,
                      color: AppColors.goldAccent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Service Course HQ',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          '${state.teamName} • ${bonuses.hqTierLabel}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: Text(
                        'Prestiż ${bonuses.hqPrestigeScore}/100',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 1200;
            final isTablet = width >= 760 && width < 1200;
            final horizontalPadding = width < 520 ? 14.0 : 24.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HqSummaryKpiBanner(
                    state: state,
                    bonuses: bonuses,
                    monthlyUpkeepEur: monthlyUpkeepEur,
                    compact: width < 640,
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 12),
                    _FeedbackToastBanner(
                      message: _statusMessage!,
                      isError: _statusIsError,
                      onDismiss: () {
                        setState(() {
                          _statusMessage = null;
                        });
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (isDesktop)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _ServiceCourseBlueprintSection(
                                state: state,
                                selectedModuleId: _selectedModuleId,
                                onSelectModule: (id) {
                                  setState(() => _selectedModuleId = id);
                                },
                              ),
                              const SizedBox(height: 18),
                              _MaintenanceAndInvestmentSection(
                                state: state,
                                bonuses: bonuses,
                                monthlyUpkeepEur: monthlyUpkeepEur,
                                onSelectModule: (id) {
                                  setState(() => _selectedModuleId = id);
                                },
                                onAdvanceDays: _handleAdvanceDays,
                                onCancelConstruction: _handleCancelConstruction,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          flex: 5,
                          child: _DepartmentInspectorSection(
                            state: state,
                            selectedModuleId: _selectedModuleId,
                            onSelectModule: (id) {
                              setState(() => _selectedModuleId = id);
                            },
                            onStartUpgrade: _handleStartUpgrade,
                            onCancelConstruction: _handleCancelConstruction,
                          ),
                        ),
                      ],
                    )
                  else if (isTablet)
                    Column(
                      children: [
                        _ServiceCourseBlueprintSection(
                          state: state,
                          selectedModuleId: _selectedModuleId,
                          onSelectModule: (id) {
                            setState(() => _selectedModuleId = id);
                          },
                        ),
                        const SizedBox(height: 18),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 6,
                              child: _DepartmentInspectorSection(
                                state: state,
                                selectedModuleId: _selectedModuleId,
                                onSelectModule: (id) {
                                  setState(() => _selectedModuleId = id);
                                },
                                onStartUpgrade: _handleStartUpgrade,
                                onCancelConstruction: _handleCancelConstruction,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 5,
                              child: _MaintenanceAndInvestmentSection(
                                state: state,
                                bonuses: bonuses,
                                monthlyUpkeepEur: monthlyUpkeepEur,
                                onSelectModule: (id) {
                                  setState(() => _selectedModuleId = id);
                                },
                                onAdvanceDays: _handleAdvanceDays,
                                onCancelConstruction: _handleCancelConstruction,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _ServiceCourseBlueprintSection(
                          state: state,
                          selectedModuleId: _selectedModuleId,
                          onSelectModule: (id) {
                            setState(() => _selectedModuleId = id);
                          },
                        ),
                        const SizedBox(height: 16),
                        _DepartmentInspectorSection(
                          state: state,
                          selectedModuleId: _selectedModuleId,
                          onSelectModule: (id) {
                            setState(() => _selectedModuleId = id);
                          },
                          onStartUpgrade: _handleStartUpgrade,
                          onCancelConstruction: _handleCancelConstruction,
                        ),
                        const SizedBox(height: 16),
                        _MaintenanceAndInvestmentSection(
                          state: state,
                          bonuses: bonuses,
                          monthlyUpkeepEur: monthlyUpkeepEur,
                          onSelectModule: (id) {
                            setState(() => _selectedModuleId = id);
                          },
                          onAdvanceDays: _handleAdvanceDays,
                          onCancelConstruction: _handleCancelConstruction,
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HqSummaryKpiBanner extends StatelessWidget {
  const _HqSummaryKpiBanner({
    required this.state,
    required this.bonuses,
    required this.monthlyUpkeepEur,
    required this.compact,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseCareerBonuses bonuses;
  final int monthlyUpkeepEur;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final maxLevels =
        ServiceCourseModuleId.values.length * TeamServiceCourseHqUpgrades.maxModuleLevel;

    final metrics = <Widget>[
      _KpiMetricTile(
        icon: Icons.account_balance_wallet_rounded,
        label: 'Dostępny budżet',
        value: Formatters.formatCurrency(state.availableBudgetEur),
        sublabel: 'Środki na rozbudowę',
        accent: AppColors.statusSuccess,
      ),
      _KpiMetricTile(
        icon: Icons.payments_outlined,
        label: 'Koszt utrzymania',
        value: '${Formatters.formatCurrency(bonuses.totalAnnualUpkeepEur)}/rok',
        sublabel: '${Formatters.formatCurrency(monthlyUpkeepEur)} / mies.',
        accent: AppColors.amberWarning,
      ),
      _KpiMetricTile(
        icon: Icons.engineering_rounded,
        label: 'Aktywne inwestycje',
        value: '${state.activeConstructionsCount}',
        sublabel: state.activeConstructionsCount == 0
            ? 'Brak prac w toku'
            : 'Rozbudowa w trakcie',
        accent: state.activeConstructionsCount > 0
            ? AppColors.cyanAccent
            : AppColors.textSecondary,
      ),
      _KpiMetricTile(
        icon: Icons.layers_rounded,
        label: 'Poziom bazy',
        value: '${state.totalLevelsBuilt} / $maxLevels',
        sublabel: 'Wartość: ${Formatters.formatCurrency(state.totalFacilityValueEur)}',
        accent: AppColors.goldAccent,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surfaceLight.withValues(alpha: 0.72),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 560;
          final isMedium =
              constraints.maxWidth >= 560 && constraints.maxWidth < 940;

          if (isNarrow) {
            return Column(
              children: [
                for (int i = 0; i < metrics.length; i++) ...[
                  metrics[i],
                  if (i < metrics.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          }

          if (isMedium) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(width: 12),
                    Expanded(child: metrics[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: metrics[2]),
                    const SizedBox(width: 12),
                    Expanded(child: metrics[3]),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              for (int i = 0; i < metrics.length; i++) ...[
                Expanded(child: metrics[i]),
                if (i < metrics.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _KpiMetricTile extends StatelessWidget {
  const _KpiMetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.sublabel,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sublabel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  sublabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: accent.withValues(alpha: 0.9),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackToastBanner extends StatelessWidget {
  const _FeedbackToastBanner({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.crimsonAlert : AppColors.statusSuccess;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textSecondary,
            ),
            tooltip: 'Zamknij komunikat',
          ),
        ],
      ),
    );
  }
}

/// Wizualizacja 5 działów Service Course w formie interaktywnego planu kampusu.
class _ServiceCourseBlueprintSection extends StatelessWidget {
  const _ServiceCourseBlueprintSection({
    required this.state,
    required this.selectedModuleId,
    required this.onSelectModule,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseModuleId selectedModuleId;
  final ValueChanged<ServiceCourseModuleId> onSelectModule;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.architecture_rounded,
                color: AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Wizualizacja 5 działów Service Course',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: const Text(
                  '5 modułów • Poziom 1–5',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Wybierz dział na schemacie bazy lub z listy poniżej, aby zarządzać rozbudową, kosztami utrzymania i czasem inwestycji.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isCompact = width < 520;
              final canvasHeight = isCompact ? 210.0 : 250.0;

              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: canvasHeight,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _ServiceCourseBlueprintPainter(
                                state: state,
                                selectedModuleId: selectedModuleId,
                              ),
                            ),
                          ),
                          ..._buildInteractiveNodes(
                            width: width,
                            height: canvasHeight,
                            isCompact: isCompact,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DepartmentCardsGrid(
                    state: state,
                    selectedModuleId: selectedModuleId,
                    onSelectModule: onSelectModule,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInteractiveNodes({
    required double width,
    required double height,
    required bool isCompact,
  }) {
    // 5 działów rozmieszczonych symetrycznie wokół centralnego węzła logistycznego.
    const positions = <ServiceCourseModuleId, Offset>{
      ServiceCourseModuleId.windTunnel: Offset(0.18, 0.28),
      ServiceCourseModuleId.hypoxiaCenter: Offset(0.82, 0.28),
      ServiceCourseModuleId.recoveryBusFleet: Offset(0.50, 0.20),
      ServiceCourseModuleId.drivetrainWaxWorkshop: Offset(0.24, 0.74),
      ServiceCourseModuleId.scoutingAcademy: Offset(0.76, 0.74),
    };

    final nodeWidth = isCompact ? 98.0 : 132.0;
    final nodeHeight = isCompact ? 56.0 : 62.0;

    return ServiceCourseModuleId.values.map((id) {
      final rel = positions[id]!;
      final left = (rel.dx * width - nodeWidth / 2)
          .clamp(8.0, math.max(8.0, width - nodeWidth - 8.0))
          .toDouble();
      final top = (rel.dy * height - nodeHeight / 2)
          .clamp(8.0, math.max(8.0, height - nodeHeight - 8.0))
          .toDouble();
      final moduleState = state.moduleState(id);
      final isSelected = id == selectedModuleId;

      return Positioned(
        left: left,
        top: top,
        width: nodeWidth,
        height: nodeHeight,
        child: _BlueprintDepartmentNode(
          moduleId: id,
          moduleState: moduleState,
          isSelected: isSelected,
          compact: isCompact,
          onTap: () => onSelectModule(id),
        ),
      );
    }).toList();
  }
}

class _ServiceCourseBlueprintPainter extends CustomPainter {
  const _ServiceCourseBlueprintPainter({
    required this.state,
    required this.selectedModuleId,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseModuleId selectedModuleId;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppTheme.borderColor.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = step; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final hubCenter = Offset(size.width * 0.5, size.height * 0.52);

    const anchors = <ServiceCourseModuleId, Offset>{
      ServiceCourseModuleId.windTunnel: Offset(0.18, 0.28),
      ServiceCourseModuleId.hypoxiaCenter: Offset(0.82, 0.28),
      ServiceCourseModuleId.recoveryBusFleet: Offset(0.50, 0.20),
      ServiceCourseModuleId.drivetrainWaxWorkshop: Offset(0.24, 0.74),
      ServiceCourseModuleId.scoutingAcademy: Offset(0.76, 0.74),
    };

    for (final entry in anchors.entries) {
      final target = Offset(
        entry.value.dx * size.width,
        entry.value.dy * size.height,
      );
      final mod = state.moduleState(entry.key);
      final isSelected = entry.key == selectedModuleId;
      final lineColor = isSelected
          ? entry.key.accentColor.withValues(alpha: 0.85)
          : (mod.currentLevel > 0
              ? entry.key.accentColor.withValues(alpha: 0.4)
              : AppTheme.borderColor.withValues(alpha: 0.6));

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = isSelected ? 2.4 : 1.4
        ..style = PaintingStyle.stroke;

      canvas.drawLine(hubCenter, target, linePaint);

      final dotPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(target, isSelected ? 4.5 : 3.0, dotPaint);
    }

    final hubOuterPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final hubBorderPaint = Paint()
      ..color = AppColors.goldAccent.withValues(alpha: 0.75)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(hubCenter, 16, hubOuterPaint);
    canvas.drawCircle(hubCenter, 16, hubBorderPaint);

    final hubCorePaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(hubCenter, 4.5, hubCorePaint);
  }

  @override
  bool shouldRepaint(covariant _ServiceCourseBlueprintPainter oldDelegate) {
    return oldDelegate.selectedModuleId != selectedModuleId ||
        oldDelegate.state != state;
  }
}

class _BlueprintDepartmentNode extends StatefulWidget {
  const _BlueprintDepartmentNode({
    required this.moduleId,
    required this.moduleState,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  final ServiceCourseModuleId moduleId;
  final ServiceCourseModuleState moduleState;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_BlueprintDepartmentNode> createState() =>
      _BlueprintDepartmentNodeState();
}

class _BlueprintDepartmentNodeState extends State<_BlueprintDepartmentNode> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.moduleId.accentColor;
    final level = widget.moduleState.currentLevel;
    final underConstruction = widget.moduleState.isUnderConstruction;

    final borderColor = widget.isSelected
        ? accent
        : _focused
            ? AppColors.goldAccent
            : _hovered
                ? accent.withValues(alpha: 0.75)
                : AppColors.cardBorder;

    final backgroundColor = widget.isSelected
        ? AppColors.surfaceLight
        : _hovered
            ? AppColors.surface
            : AppColors.surface.withValues(alpha: 0.92);

    return FocusableActionDetector(
      onShowHoverHighlight: (value) => setState(() => _hovered = value),
      onShowFocusHighlight: (value) => setState(() => _focused = value),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.compact ? 7 : 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: borderColor,
                  width: widget.isSelected || _focused ? 1.6 : 1.0,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.24),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(widget.moduleId.icon, color: accent, size: 14),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.moduleId.shortTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: widget.compact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Poz. $level/5',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: widget.compact ? 9 : 10,
                            fontWeight: FontWeight.w600,
                            color: level > 0 ? accent : AppColors.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (underConstruction) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyanAccent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${widget.moduleState.remainingConstructionDays}d',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cyanAccent,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ],
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

class _DepartmentCardsGrid extends StatelessWidget {
  const _DepartmentCardsGrid({
    required this.state,
    required this.selectedModuleId,
    required this.onSelectModule,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseModuleId selectedModuleId;
  final ValueChanged<ServiceCourseModuleId> onSelectModule;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 660 ? 3 : (width >= 420 ? 2 : 1);
        const spacing = 10.0;
        final cardWidth =
            (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: ServiceCourseModuleId.values.map((id) {
            final moduleState = state.moduleState(id);
            final spec = moduleState.currentLevel > 0
                ? TeamServiceCourseHqUpgrades.definitionFor(id)
                    .specForLevel(moduleState.currentLevel)
                : null;
            return SizedBox(
              width: cardWidth,
              child: _DepartmentSummaryTile(
                moduleId: id,
                moduleState: moduleState,
                activeSpec: spec,
                isSelected: id == selectedModuleId,
                onTap: () => onSelectModule(id),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _DepartmentSummaryTile extends StatefulWidget {
  const _DepartmentSummaryTile({
    required this.moduleId,
    required this.moduleState,
    required this.activeSpec,
    required this.isSelected,
    required this.onTap,
  });

  final ServiceCourseModuleId moduleId;
  final ServiceCourseModuleState moduleState;
  final ServiceCourseModuleLevelSpec? activeSpec;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_DepartmentSummaryTile> createState() => _DepartmentSummaryTileState();
}

class _DepartmentSummaryTileState extends State<_DepartmentSummaryTile> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.moduleId.accentColor;
    final annualUpkeep = widget.activeSpec?.annualUpkeepEur ?? 0;

    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.surfaceLight
                    : _hovered
                        ? AppColors.surfaceLight.withValues(alpha: 0.55)
                        : AppColors.background.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: widget.isSelected
                      ? accent
                      : _focused
                          ? AppColors.goldAccent
                          : _hovered
                              ? accent.withValues(alpha: 0.6)
                              : AppColors.cardBorder,
                  width: widget.isSelected || _focused ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(widget.moduleId.icon, color: accent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.moduleId.shortTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.moduleState.currentLevel}/5',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: accent,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _LevelSegmentsIndicator(
                    currentLevel: widget.moduleState.currentLevel,
                    targetLevel: widget.moduleState.targetLevel,
                    accent: accent,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          annualUpkeep > 0
                              ? '${Formatters.formatCurrency(annualUpkeep)}/rok'
                              : 'Brak utrzymania',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if (widget.moduleState.isUnderConstruction)
                        Text(
                          'Budowa: ${widget.moduleState.remainingConstructionDays} d',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyanAccent,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
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

class _LevelSegmentsIndicator extends StatelessWidget {
  const _LevelSegmentsIndicator({
    required this.currentLevel,
    required this.targetLevel,
    required this.accent,
  });

  final int currentLevel;
  final int? targetLevel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(5, (index) {
        final level = index + 1;
        final isBuilt = level <= currentLevel;
        final isBuilding = targetLevel != null && level == targetLevel;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            height: 6,
            margin: EdgeInsets.only(right: index < 4 ? 4 : 0),
            decoration: BoxDecoration(
              color: isBuilt
                  ? accent
                  : isBuilding
                      ? AppColors.cyanAccent.withValues(alpha: 0.75)
                      : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isBuilt
                    ? accent
                    : isBuilding
                        ? AppColors.cyanAccent
                        : AppColors.cardBorder,
                width: 0.5,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Szczegółowy inspektor wybranego działu oraz pełna ścieżka Poziom 1–5.
class _DepartmentInspectorSection extends StatelessWidget {
  const _DepartmentInspectorSection({
    required this.state,
    required this.selectedModuleId,
    required this.onSelectModule,
    required this.onStartUpgrade,
    required this.onCancelConstruction,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseModuleId selectedModuleId;
  final ValueChanged<ServiceCourseModuleId> onSelectModule;
  final ValueChanged<ServiceCourseModuleId> onStartUpgrade;
  final ValueChanged<ServiceCourseModuleId> onCancelConstruction;

  @override
  Widget build(BuildContext context) {
    final definition = TeamServiceCourseHqUpgrades.definitionFor(selectedModuleId);
    final moduleState = state.moduleState(selectedModuleId);
    final validation =
        TeamServiceCourseHqUpgrades.canStartUpgrade(state, selectedModuleId);
    final accent = selectedModuleId.accentColor;

    final currentSpec = moduleState.currentLevel > 0
        ? definition.specForLevel(moduleState.currentLevel)
        : null;
    final nextLevel = moduleState.currentLevel < definition.maxLevel
        ? moduleState.currentLevel + 1
        : null;
    final nextSpec =
        nextLevel != null ? definition.specForLevel(nextLevel) : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Icon(selectedModuleId.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedModuleId.categoryTag,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: accent,
                      ),
                    ),
                    Text(
                      selectedModuleId.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  'Poziom ${moduleState.currentLevel}/5',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            selectedModuleId.summary,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        currentSpec != null
                            ? 'Aktywny: ${currentSpec.tierName}'
                            : 'Dział nie został jeszcze wybudowany',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (currentSpec != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${Formatters.formatCurrency(currentSpec.annualUpkeepEur)}/rok',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amberWarning,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ],
                ),
                if (currentSpec != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${currentSpec.primaryBonusLabel}: +${currentSpec.primaryBonusValue.toStringAsFixed(1)} • ${currentSpec.secondaryBonusLabel}: +${currentSpec.secondaryBonusValue.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                ],
                if (moduleState.isUnderConstruction) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: moduleState.constructionProgress,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.cyanAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Trwa rozbudowa do Poziomu ${moduleState.targetLevel}: pozostało ${moduleState.remainingConstructionDays} z ${moduleState.totalConstructionDays} dni',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cyanAccent,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (moduleState.isUnderConstruction)
            _InteractiveHqButton(
              label: 'Anuluj budowę (zwrot 50%)',
              icon: Icons.cancel_outlined,
              accent: AppColors.crimsonAlert,
              enabled: true,
              onPressed: () => onCancelConstruction(selectedModuleId),
            )
          else if (nextSpec != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InteractiveHqButton(
                  label:
                      'Rozbuduj do Poziomu ${nextSpec.level} • ${Formatters.formatCurrency(nextSpec.buildCostEur)} (${nextSpec.constructionDays} dni)',
                  icon: Icons.upgrade_rounded,
                  accent: AppColors.goldAccent,
                  enabled: validation.canUpgrade,
                  onPressed: () => onStartUpgrade(selectedModuleId),
                ),
                if (!validation.canUpgrade && validation.reason != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    validation.reason!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.crimsonAlert,
                    ),
                  ),
                ],
              ],
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.statusSuccess.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.statusSuccess.withValues(alpha: 0.5),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.statusSuccess,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Osiągnięto maksymalny Poziom 5/5',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusSuccess,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Poziomy rozbudowy (Poziom 1–5)',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...definition.levels.map((spec) {
            final isCompleted = spec.level <= moduleState.currentLevel;
            final isInProgress = moduleState.isUnderConstruction &&
                moduleState.targetLevel == spec.level;
            final isNext = !moduleState.isUnderConstruction &&
                spec.level == moduleState.currentLevel + 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LevelTierRow(
                spec: spec,
                accent: accent,
                isCompleted: isCompleted,
                isInProgress: isInProgress,
                isNext: isNext,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _LevelTierRow extends StatelessWidget {
  const _LevelTierRow({
    required this.spec,
    required this.accent,
    required this.isCompleted,
    required this.isInProgress,
    required this.isNext,
  });

  final ServiceCourseModuleLevelSpec spec;
  final Color accent;
  final bool isCompleted;
  final bool isInProgress;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final statusColor = isCompleted
        ? AppColors.statusSuccess
        : isInProgress
            ? AppColors.cyanAccent
            : isNext
                ? AppColors.goldAccent
                : AppColors.textSecondary;

    final statusLabel = isCompleted
        ? 'Ukończony'
        : isInProgress
            ? 'W budowie'
            : isNext
                ? 'Następny'
                : 'Zablokowany';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNext || isInProgress
            ? AppColors.surfaceLight.withValues(alpha: 0.72)
            : AppColors.background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isInProgress
              ? AppColors.cyanAccent.withValues(alpha: 0.7)
              : isNext
                  ? AppColors.goldAccent.withValues(alpha: 0.6)
                  : isCompleted
                      ? accent.withValues(alpha: 0.4)
                      : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Poziom ${spec.level}',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  spec.tierName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            spec.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _SpecTag(
                icon: Icons.euro_rounded,
                label: 'Koszt: ${Formatters.formatCurrency(spec.buildCostEur)}',
              ),
              _SpecTag(
                icon: Icons.payments_outlined,
                label:
                    'Utrzymanie: ${Formatters.formatCurrency(spec.annualUpkeepEur)}/rok',
              ),
              _SpecTag(
                icon: Icons.schedule_rounded,
                label: 'Czas: ${spec.constructionDays} dni',
              ),
              _SpecTag(
                icon: Icons.trending_up_rounded,
                label:
                    '${spec.primaryBonusLabel} +${spec.primaryBonusValue.toStringAsFixed(1)}',
                color: accent,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecTag extends StatelessWidget {
  const _SpecTag({
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Sekcja kosztów utrzymania, czasu inwestycji oraz historii rozbudowy.
class _MaintenanceAndInvestmentSection extends StatelessWidget {
  const _MaintenanceAndInvestmentSection({
    required this.state,
    required this.bonuses,
    required this.monthlyUpkeepEur,
    required this.onSelectModule,
    required this.onAdvanceDays,
    required this.onCancelConstruction,
  });

  final TeamServiceCourseHqState state;
  final ServiceCourseCareerBonuses bonuses;
  final int monthlyUpkeepEur;
  final ValueChanged<ServiceCourseModuleId> onSelectModule;
  final ValueChanged<int> onAdvanceDays;
  final ValueChanged<ServiceCourseModuleId> onCancelConstruction;

  @override
  Widget build(BuildContext context) {
    final activeConstructions = state.modules.values
        .where((m) => m.isUnderConstruction)
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: AppColors.amberWarning,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Koszty utrzymania i czas inwestycji',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${Formatters.formatCurrency(monthlyUpkeepEur)}/mies.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amberWarning,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...ServiceCourseModuleId.values.map((id) {
            final mod = state.moduleState(id);
            final spec = mod.currentLevel > 0
                ? TeamServiceCourseHqUpgrades.definitionFor(id)
                    .specForLevel(mod.currentLevel)
                : null;
            final annualCost = spec?.annualUpkeepEur ?? 0;
            final share = bonuses.totalAnnualUpkeepEur > 0
                ? (annualCost / bonuses.totalAnnualUpkeepEur).clamp(0.0, 1.0)
                : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => onSelectModule(id),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '${id.shortTitle} (Poz. ${mod.currentLevel})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '${Formatters.formatCurrency(annualCost)}/rok',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: share,
                          minHeight: 5,
                          backgroundColor: AppColors.background,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(id.accentColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Divider(color: AppTheme.borderColor, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Harmonogram inwestycji',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (activeConstructions.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    _MiniTimeButton(
                      label: '+1 dzień',
                      onPressed: () => onAdvanceDays(1),
                    ),
                    _MiniTimeButton(
                      label: '+7 dni',
                      onPressed: () => onAdvanceDays(7),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (activeConstructions.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Brak aktywnych inwestycji budowlanych. Wybierz dział i rozpocznij rozbudowę.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...activeConstructions.map((mod) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cyanAccent.withValues(alpha: 0.45),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${mod.moduleId.shortTitle} → Poziom ${mod.targetLevel}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${mod.remainingConstructionDays} dni',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.cyanAccent,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: mod.constructionProgress,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.cyanAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (state.upgradeHistory.isNotEmpty) ...[
            const Divider(color: AppTheme.borderColor, height: 24),
            const Text(
              'Ostatnie zdarzenia inwestycyjne',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ...state.upgradeHistory.take(4).map((event) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      event.eventType == 'completed'
                          ? Icons.check_circle_outline_rounded
                          : event.eventType == 'cancelled'
                              ? Icons.undo_rounded
                              : Icons.construction_rounded,
                      size: 14,
                      color: event.eventType == 'completed'
                          ? AppColors.statusSuccess
                          : event.eventType == 'cancelled'
                              ? AppColors.crimsonAlert
                              : AppColors.cyanAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _MiniTimeButton extends StatefulWidget {
  const _MiniTimeButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_MiniTimeButton> createState() => _MiniTimeButtonState();
}

class _MiniTimeButtonState extends State<_MiniTimeButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceLight : AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : _hovered
                        ? AppColors.cyanAccent
                        : AppColors.cardBorder,
              ),
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.cyanAccent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InteractiveHqButton extends StatefulWidget {
  const _InteractiveHqButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_InteractiveHqButton> createState() => _InteractiveHqButtonState();
}

class _InteractiveHqButtonState extends State<_InteractiveHqButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent =
        widget.enabled ? widget.accent : AppColors.textSecondary;

    return FocusableActionDetector(
      enabled: widget.enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            if (widget.enabled) widget.onPressed();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.enabled ? widget.onPressed : null,
          onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.985 : 1.0,
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: widget.enabled
                    ? (_hovered
                        ? effectiveAccent.withValues(alpha: 0.24)
                        : effectiveAccent.withValues(alpha: 0.14))
                    : AppColors.surfaceLight.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : widget.enabled
                          ? effectiveAccent.withValues(alpha: _hovered ? 0.9 : 0.6)
                          : AppColors.cardBorder,
                  width: _focused ? 1.6 : 1.0,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 18,
                    color: widget.enabled
                        ? effectiveAccent
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: widget.enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
