import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/uci/technical_scrutiny_and_cas_tribunal_model.dart';

/// Akcja podjęta przez menedżera lub komisarza w modalu skanera X-Ray UCI.
enum UciXrayScrutinyModalAction {
  clearedForStart,
  torqueCorrectionApplied,
  impoundedOrDisqualified,
  dismissed,
}

/// Wynik zamknięcia modalu [UciTechnicalXrayScrutinyModal].
class UciXrayScrutinyModalResult {
  final UciXrayScrutinyModalAction action;
  final TechnicalScrutinyInspectionRecord record;
  final bool cockpitCorrected;

  const UciXrayScrutinyModalResult({
    required this.action,
    required this.record,
    this.cockpitCorrected = false,
  });
}

/// Wyświetla klimatyczny modal przedstartowej kontroli technicznej UCI (skaner X-Ray).
Future<UciXrayScrutinyModalResult?> showUciTechnicalXrayScrutinyModal(
  BuildContext context, {
  TechnicalScrutinyInspectionRecord? inspectionRecord,
  bool autoStartScan = true,
}) {
  return showDialog<UciXrayScrutinyModalResult>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: UciTechnicalXrayScrutinyModal(
          inspectionRecord: inspectionRecord,
          autoStartScan: autoStartScan,
          onCompleted: (result) {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop(result);
            }
          },
          onClose: () {
            if (Navigator.of(dialogContext).canPop()) {
              Navigator.of(dialogContext).pop();
            }
          },
        ),
      );
    },
  );
}

/// Klimatyczny modal przedstartowej kontroli technicznej UCI z wizualizacją
/// skanera rentgenowskiego prześwietlającego rower wyścigowy (suport, rura
/// podsiodłowa, piasty, kokpit), zielonymi znacznikami zgodności z regulaminem
/// UCI oraz alarmem w przypadku wykrycia nieregulaminowego ustawienia kokpitu.
class UciTechnicalXrayScrutinyModal extends StatefulWidget {
  final TechnicalScrutinyInspectionRecord? inspectionRecord;
  final bool autoStartScan;
  final ValueChanged<UciXrayScrutinyModalResult>? onCompleted;
  final VoidCallback? onClose;

  const UciTechnicalXrayScrutinyModal({
    super.key,
    this.inspectionRecord,
    this.autoStartScan = true,
    this.onCompleted,
    this.onClose,
  });

  /// Buduje domyślny przedstartowy protokół inspekcji z wykrytym alarmem kokpitu,
  /// gdy nie przekazano zewnętrznego obiektu [TechnicalScrutinyInspectionRecord].
  static TechnicalScrutinyInspectionRecord buildDefaultPreStartRecord({
    bool withCockpitAlarm = true,
  }) {
    final double leverAngle = withCockpitAlarm ? 14.8 : 7.5;
    return TechnicalScrutinyInspectionRecord(
      inspectionId: 'UCI-XRAY-PRE-2026-041',
      raceId: 'tour_de_france',
      stageNumber: 1,
      riderId: 'rider_leader_01',
      riderName: 'T. Vingegaard-Kowalski',
      teamId: 'team_obsidian_pro',
      timingWindow: ScrutinyTimingWindow.preStartPaddock,
      selectionMode: ScrutinySelectionMode.targetedGcLeader,
      devicesUsed: const [
        ScrutinyDeviceType.mobileXrayScanner,
        ScrutinyDeviceType.magneticInductionTablet,
        ScrutinyDeviceType.leverAngleInclinometer,
        ScrutinyDeviceType.calibratedScale,
      ],
      measurements: RiderEquipmentMeasurements(
        riderId: 'rider_leader_01',
        riderName: 'T. Vingegaard-Kowalski',
        teamId: 'team_obsidian_pro',
        frameSerialNumber: 'UCI-FRM-99482-PL',
        bikeWeightKg: 6.86,
        sockHeightCm: 17.5,
        shinLengthCm: 39.0,
        brakeLeverTiltDeg: leverAngle,
        ttExtensionReachMm: 760.0,
        isTimeTrialSetup: false,
        frameJigCompliant: true,
        measuredAtIso: '2026-07-04T09:42:00Z',
      ),
      xrayScans: const [
        XrayAndMagneticScanTelemetry(
          scanId: 'SCAN-BB-01',
          deviceType: ScrutinyDeviceType.mobileXrayScanner,
          zone: EquipmentInspectionZone.bottomBracketShell,
          magneticFluxMicroTesla: 11.4,
          xrayMetalDensityScore: 0.28,
          hiddenMotorSignatureDetected: false,
          unusualBatteryCellDetected: false,
          serialNumberVerified: true,
          scanDurationSeconds: 14,
          operatorCommissaireId: 'COMM-UCI-77',
          timestampIso: '2026-07-04T09:41:15Z',
        ),
        XrayAndMagneticScanTelemetry(
          scanId: 'SCAN-ST-02',
          deviceType: ScrutinyDeviceType.mobileXrayScanner,
          zone: EquipmentInspectionZone.seatTubeAndBattery,
          magneticFluxMicroTesla: 14.2,
          xrayMetalDensityScore: 0.34,
          hiddenMotorSignatureDetected: false,
          unusualBatteryCellDetected: false,
          serialNumberVerified: true,
          scanDurationSeconds: 12,
          operatorCommissaireId: 'COMM-UCI-77',
          timestampIso: '2026-07-04T09:41:30Z',
        ),
        XrayAndMagneticScanTelemetry(
          scanId: 'SCAN-HUB-03',
          deviceType: ScrutinyDeviceType.magneticInductionTablet,
          zone: EquipmentInspectionZone.rearHubMotorCheck,
          magneticFluxMicroTesla: 9.8,
          xrayMetalDensityScore: 0.31,
          hiddenMotorSignatureDetected: false,
          unusualBatteryCellDetected: false,
          serialNumberVerified: true,
          scanDurationSeconds: 10,
          operatorCommissaireId: 'COMM-UCI-77',
          timestampIso: '2026-07-04T09:41:45Z',
        ),
      ],
      zoneResults: [
        const ScrutinyZoneCheckResult(
          zone: EquipmentInspectionZone.bottomBracketShell,
          severity: ScrutinyFindingSeverity.compliant,
          measuredValue: 11.4,
          limitValue: 45.0,
          unit: 'µT',
          passed: true,
          requiresImmediateTorqueCorrection: false,
          notePl: 'Mufa suportowa czysta — brak sygnatury silnika.',
        ),
        const ScrutinyZoneCheckResult(
          zone: EquipmentInspectionZone.seatTubeAndBattery,
          severity: ScrutinyFindingSeverity.compliant,
          measuredValue: 0.34,
          limitValue: 0.65,
          unit: 'g/cm³',
          passed: true,
          requiresImmediateTorqueCorrection: false,
          notePl: 'Rura podsiodłowa zgodna — wyłącznie standardowe ogniwo Di2.',
        ),
        const ScrutinyZoneCheckResult(
          zone: EquipmentInspectionZone.rearHubMotorCheck,
          severity: ScrutinyFindingSeverity.compliant,
          measuredValue: 9.8,
          limitValue: 45.0,
          unit: 'µT',
          passed: true,
          requiresImmediateTorqueCorrection: false,
          notePl: 'Tylna i przednia piasta wolne od pola elektromagnetycznego.',
        ),
        ScrutinyZoneCheckResult(
          zone: EquipmentInspectionZone.handlebarBrakeLevers,
          severity: withCockpitAlarm
              ? ScrutinyFindingSeverity.minorTechnicalWarning
              : ScrutinyFindingSeverity.compliant,
          measuredValue: leverAngle,
          limitValue: 10.0,
          unit: '°',
          passed: !withCockpitAlarm,
          requiresImmediateTorqueCorrection: withCockpitAlarm,
          notePl: withCockpitAlarm
              ? 'ALARM: Kąt klamek ${leverAngle.toStringAsFixed(1)}° przekracza limit UCI 10.0° (Art. 1.3.022).'
              : 'Kokpit zgodny: kąt klamek ${leverAngle.toStringAsFixed(1)}° <= 10.0°.',
        ),
      ],
      overallOutcome: withCockpitAlarm
          ? ScrutinySessionOutcome.passedAfterTorqueCorrection
          : ScrutinySessionOutcome.passedClean,
      fineChf: withCockpitAlarm ? 500.0 : 0.0,
      uciPointsDeducted: 0,
      riderStressSpikeDelta: withCockpitAlarm ? 4.5 : 0.8,
      riderFocusDropDelta: withCockpitAlarm ? 2.5 : 0.0,
      torqueCorrectionSeconds: withCockpitAlarm ? 45 : 0,
      commissaireName: 'Jean-Luc Moreau (UCI)',
      inspectedAtIso: '2026-07-04T09:42:00Z',
    );
  }

  @override
  State<UciTechnicalXrayScrutinyModal> createState() =>
      _UciTechnicalXrayScrutinyModalState();
}

class _UciTechnicalXrayScrutinyModalState
    extends State<UciTechnicalXrayScrutinyModal>
    with TickerProviderStateMixin {
  late TechnicalScrutinyInspectionRecord _record;
  late AnimationController _scanBeamController;
  late AnimationController _alarmPulseController;

  EquipmentInspectionZone _selectedZone =
      EquipmentInspectionZone.bottomBracketShell;
  bool _cockpitCorrected = false;
  bool _isScanning = false;

  static const List<EquipmentInspectionZone> _primaryZones = [
    EquipmentInspectionZone.bottomBracketShell,
    EquipmentInspectionZone.seatTubeAndBattery,
    EquipmentInspectionZone.rearHubMotorCheck,
    EquipmentInspectionZone.handlebarBrakeLevers,
  ];

  @override
  void initState() {
    super.initState();
    _record = widget.inspectionRecord ??
        UciTechnicalXrayScrutinyModal.buildDefaultPreStartRecord();

    _scanBeamController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _alarmPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);

    if (_hasCockpitViolation) {
      _selectedZone = _cockpitZoneResult?.zone ??
          EquipmentInspectionZone.handlebarBrakeLevers;
    }

    if (widget.autoStartScan) {
      _startXraySweep();
    }
  }

  @override
  void didUpdateWidget(covariant UciTechnicalXrayScrutinyModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.inspectionRecord != oldWidget.inspectionRecord &&
        widget.inspectionRecord != null) {
      _record = widget.inspectionRecord!;
      _cockpitCorrected = false;
    }
  }

  @override
  void dispose() {
    _scanBeamController.dispose();
    _alarmPulseController.dispose();
    super.dispose();
  }

  void _startXraySweep() {
    setState(() {
      _isScanning = true;
    });
    _scanBeamController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  ScrutinyZoneCheckResult? get _cockpitZoneResult {
    for (final z in _record.zoneResults) {
      if (z.zone == EquipmentInspectionZone.handlebarBrakeLevers ||
          z.zone == EquipmentInspectionZone.ttExtensionLength) {
        return z;
      }
    }
    return null;
  }

  bool get _hasCockpitViolation {
    final cockpit = _cockpitZoneResult;
    if (cockpit != null && !cockpit.passed) return true;
    return !_record.measurements.isLeverTiltCompliant ||
        !_record.measurements.isTtExtensionCompliant;
  }

  bool get _hasCriticalMotorCheat {
    return _record.xrayScans.any(
      (s) => s.hiddenMotorSignatureDetected || s.unusualBatteryCellDetected,
    );
  }

  bool get _canProceedToStart {
    return !_hasCockpitViolation && !_hasCriticalMotorCheat;
  }

  void _applyCockpitTorqueCorrection() {
    if (!_hasCockpitViolation || _hasCriticalMotorCheat) return;

    final updatedZones = _record.zoneResults.map((zone) {
      if (zone.zone == EquipmentInspectionZone.handlebarBrakeLevers) {
        return zone.copyWith(
          severity: ScrutinyFindingSeverity.compliant,
          measuredValue: 8.5,
          passed: true,
          requiresImmediateTorqueCorrection: false,
          notePl: 'Skorygowano przed startem: kąt klamek 8.5° <= 10.0°.',
        );
      }
      if (zone.zone == EquipmentInspectionZone.ttExtensionLength) {
        return zone.copyWith(
          severity: ScrutinyFindingSeverity.compliant,
          measuredValue: 785.0,
          passed: true,
          requiresImmediateTorqueCorrection: false,
          notePl: 'Skorygowano przed startem: wysięg TT 785 mm <= 800 mm.',
        );
      }
      return zone;
    }).toList(growable: false);

    final updatedMeasurements = _record.measurements.copyWith(
      brakeLeverTiltDeg: _record.measurements.isLeverTiltCompliant
          ? _record.measurements.brakeLeverTiltDeg
          : 8.5,
      ttExtensionReachMm: _record.measurements.isTtExtensionCompliant
          ? _record.measurements.ttExtensionReachMm
          : 785.0,
    );

    setState(() {
      _cockpitCorrected = true;
      _record = _record.copyWith(
        measurements: updatedMeasurements,
        zoneResults: updatedZones,
        overallOutcome: ScrutinySessionOutcome.passedAfterTorqueCorrection,
      );
    });
    _startXraySweep();
  }

  void _handleFinishStart() {
    if (!_canProceedToStart) return;
    final action = _cockpitCorrected
        ? UciXrayScrutinyModalAction.torqueCorrectionApplied
        : UciXrayScrutinyModalAction.clearedForStart;
    final result = UciXrayScrutinyModalResult(
      action: action,
      record: _record,
      cockpitCorrected: _cockpitCorrected,
    );
    if (widget.onCompleted != null) {
      widget.onCompleted!(result);
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(result);
    }
  }

  void _handleDismiss() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(
        UciXrayScrutinyModalResult(
          action: UciXrayScrutinyModalAction.dismissed,
          record: _record,
          cockpitCorrected: _cockpitCorrected,
        ),
      );
    }
  }

  ScrutinyZoneCheckResult _zoneResultFor(EquipmentInspectionZone zone) {
    for (final z in _record.zoneResults) {
      if (z.zone == zone) return z;
    }
    return ScrutinyZoneCheckResult(
      zone: zone,
      severity: ScrutinyFindingSeverity.compliant,
      measuredValue: 0.0,
      limitValue: 45.0,
      unit: 'µT',
      passed: true,
      requiresImmediateTorqueCorrection: false,
      notePl: 'Strefa zweryfikowana w normie UCI.',
    );
  }

  XrayAndMagneticScanTelemetry? _scanForZone(EquipmentInspectionZone zone) {
    for (final s in _record.xrayScans) {
      if (s.zone == zone) return s;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final double height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        final bool isCompact = width < 760;
        final bool isDesktop = width >= 1100;
        final double modalMaxWidth = isDesktop ? 1140 : (isCompact ? width : 940);
        final double modalMaxHeight =
            math.min(height, isCompact ? height : 780);

        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: modalMaxWidth,
            maxHeight: modalMaxHeight,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasCockpitViolation
                    ? AppColors.crimsonAlert.withValues(alpha: 0.65)
                    : AppColors.cardBorder,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_hasCockpitViolation
                          ? AppColors.crimsonAlert
                          : AppColors.cyanAccent)
                      .withValues(alpha: 0.14),
                  blurRadius: 32,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isCompact),
                const Divider(height: 1, color: AppColors.cardBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 12 : 20),
                    child: isCompact
                        ? _buildCompactBody()
                        : _buildWideBody(isDesktop: isDesktop),
                  ),
                ),
                const Divider(height: 1, color: AppColors.cardBorder),
                _buildFooter(isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isCompact) {
    final Color statusColor = _hasCriticalMotorCheat
        ? AppColors.crimsonAlert
        : (_hasCockpitViolation
            ? AppColors.crimsonAlert
            : AppColors.statusSuccess);
    final String statusText = _hasCriticalMotorCheat
        ? 'KRYTYCZNY ALARM X-RAY'
        : (_hasCockpitViolation
            ? 'ALARM KOKPITU UCI'
            : 'ZGODNOŚĆ UCI POTWIERDZONA');

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: isCompact ? 12 : 14,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.document_scanner_outlined,
              color: AppColors.cyanAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KONTROLA TECHNICZNA UCI — SKANER X-RAY',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isCompact ? 13 : 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_record.riderName} • ${_record.timingWindow.displayNamePl} • ${_record.measurements.frameSerialNumber}',
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
          if (!isCompact) ...[
            const SizedBox(width: 12),
            AnimatedBuilder(
              animation: _alarmPulseController,
              builder: (context, _) {
                final double pulse = _hasCockpitViolation
                    ? 0.65 + 0.35 * _alarmPulseController.value
                    : 1.0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14 * pulse),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.7 * pulse),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasCockpitViolation || _hasCriticalMotorCheat
                            ? Icons.warning_amber_rounded
                            : Icons.verified_rounded,
                        size: 15,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(width: 8),
          _XrayActionIconButton(
            icon: Icons.close_rounded,
            tooltip: 'Zamknij okno kontroli',
            onPressed: _handleDismiss,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildXrayViewport(height: 235),
        const SizedBox(height: 12),
        if (_hasCockpitViolation) ...[
          _buildCockpitAlarmBanner(),
          const SizedBox(height: 12),
        ],
        _buildSelectedZoneTelemetryCard(),
        const SizedBox(height: 12),
        _buildZonesChecklistCard(),
      ],
    );
  }

  Widget _buildWideBody({required bool isDesktop}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: isDesktop ? 7 : 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildXrayViewport(height: isDesktop ? 370 : 320),
              const SizedBox(height: 14),
              if (_hasCockpitViolation) ...[
                _buildCockpitAlarmBanner(),
                const SizedBox(height: 14),
              ],
              _buildBikeMetrologyStrip(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSelectedZoneTelemetryCard(),
              const SizedBox(height: 14),
              _buildZonesChecklistCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildXrayViewport({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF070A0F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasCockpitViolation
              ? AppColors.crimsonAlert.withValues(alpha: 0.55)
              : AppColors.accentBlue.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _scanBeamController,
                _alarmPulseController,
              ]),
              builder: (context, _) {
                return CustomPaint(
                  painter: UciBikeXrayScannerPainter(
                    scanProgress:
                        _isScanning ? _scanBeamController.value : 1.0,
                    isScanning: _isScanning,
                    alarmPulse: _alarmPulseController.value,
                    selectedZone: _selectedZone,
                    bottomBracketCompliant: _zoneResultFor(
                      EquipmentInspectionZone.bottomBracketShell,
                    ).passed,
                    seatTubeCompliant: _zoneResultFor(
                      EquipmentInspectionZone.seatTubeAndBattery,
                    ).passed,
                    hubsCompliant: _zoneResultFor(
                      EquipmentInspectionZone.rearHubMotorCheck,
                    ).passed,
                    cockpitCompliant: !_hasCockpitViolation,
                    leverTiltDeg: _record.measurements.brakeLeverTiltDeg,
                    isTimeTrialSetup: _record.measurements.isTimeTrialSetup,
                  ),
                );
              },
            ),
          ),
          // Interaktywne punkty klikalne nad strefami roweru
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, box) {
                return Stack(
                  children: [
                    _buildHotspotHitbox(
                      box: box,
                      normX: 0.45,
                      normY: 0.67,
                      zone: EquipmentInspectionZone.bottomBracketShell,
                      label: 'Suport',
                    ),
                    _buildHotspotHitbox(
                      box: box,
                      normX: 0.39,
                      normY: 0.43,
                      zone: EquipmentInspectionZone.seatTubeAndBattery,
                      label: 'Rura podsiodłowa',
                    ),
                    _buildHotspotHitbox(
                      box: box,
                      normX: 0.23,
                      normY: 0.66,
                      zone: EquipmentInspectionZone.rearHubMotorCheck,
                      label: 'Piasta tylna',
                    ),
                    _buildHotspotHitbox(
                      box: box,
                      normX: 0.70,
                      normY: 0.31,
                      zone: EquipmentInspectionZone.handlebarBrakeLevers,
                      label: 'Kokpit',
                    ),
                  ],
                );
              },
            ),
          ),
          // Górny pasek HUD skanera X-Ray
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: _buildScannerChip(
                    icon: Icons.radar_rounded,
                    label: _isScanning
                        ? 'PRZEŚWIETLANIE 140 kVp...'
                        : 'SKAN X-RAY ZAKOŃCZONY',
                    color: _isScanning
                        ? AppColors.cyanAccent
                        : AppColors.statusSuccess,
                  ),
                ),
                const SizedBox(width: 8),
                _XrayPillButton(
                  label: 'Ponów skan',
                  icon: Icons.refresh_rounded,
                  onPressed: _isScanning ? null : _startXraySweep,
                ),
              ],
            ),
          ),
          // Dolna legenda stref na ekranie X-Ray
          Positioned(
            bottom: 10,
            left: 12,
            right: 12,
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildLegendBadge(
                  color: AppColors.statusSuccess,
                  label: 'Zgodność UCI',
                ),
                if (_hasCockpitViolation)
                  _buildLegendBadge(
                    color: AppColors.crimsonAlert,
                    label: 'Alarm kokpitu (>10°)',
                  ),
                _buildLegendBadge(
                  color: AppColors.cyanAccent,
                  label: 'Wiązka X-Ray / µT',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotspotHitbox({
    required BoxConstraints box,
    required double normX,
    required double normY,
    required EquipmentInspectionZone zone,
    required String label,
  }) {
    final double left = box.maxWidth * normX - 24;
    final double top = box.maxHeight * normY - 24;
    final bool isSelected = _selectedZone == zone;

    return Positioned(
      left: left,
      top: top,
      width: 48,
      height: 48,
      child: Tooltip(
        message: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() => _selectedZone = zone),
            borderRadius: BorderRadius.circular(24),
            hoverColor: AppColors.cyanAccent.withValues(alpha: 0.14),
            focusColor: AppColors.goldAccent.withValues(alpha: 0.25),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: label,
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScannerChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBadge({required Color color, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCockpitAlarmBanner() {
    final double measuredAngle = _record.measurements.brakeLeverTiltDeg;
    return AnimatedBuilder(
      animation: _alarmPulseController,
      builder: (context, _) {
        final double glow = 0.55 + 0.45 * _alarmPulseController.value;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.crimsonAlert.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.crimsonAlert.withValues(alpha: 0.75 * glow),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.gpp_bad_rounded,
                    color: AppColors.crimsonAlert,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ALARM UCI: NIEREGULAMINOWE USTAWIENIE KOKPITU',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: AppColors.crimsonAlert,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Inklinometr wykrył pochylenie klamek ${measuredAngle.toStringAsFixed(1)}° '
                '(limit UCI Art. 1.3.022: <= 10.0°). Start zablokowany do czasu korekty mechanika.',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: _XrayPrimaryButton(
                  label: 'Korekta kokpitu (klucz dynamometryczny)',
                  icon: Icons.build_circle_outlined,
                  accentColor: AppColors.amberWarning,
                  onPressed: _applyCockpitTorqueCorrection,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBikeMetrologyStrip() {
    final m = _record.measurements;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          _buildMetricPill(
            label: 'Masa roweru',
            value: '${m.bikeWeightKg.toStringAsFixed(2)} kg',
            isOk: m.isWeightCompliant,
          ),
          _buildMetricPill(
            label: 'Kąt klamek',
            value: '${m.brakeLeverTiltDeg.toStringAsFixed(1)}°',
            isOk: m.isLeverTiltCompliant,
          ),
          _buildMetricPill(
            label: 'Skarpetki',
            value: '${(m.sockToShinRatio * 100).toStringAsFixed(0)}% goleni',
            isOk: m.isSockCompliant,
          ),
          _buildMetricPill(
            label: 'Komisarz',
            value: _record.commissaireName,
            isOk: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required bool isOk,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOk ? Icons.check_circle_outline : Icons.error_outline,
              size: 13,
              color: isOk ? AppColors.statusSuccess : AppColors.crimsonAlert,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isOk ? AppColors.textPrimary : AppColors.crimsonAlert,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedZoneTelemetryCard() {
    final zoneResult = _zoneResultFor(_selectedZone);
    final scan = _scanForZone(_selectedZone);
    final Color toneColor =
        zoneResult.passed ? AppColors.statusSuccess : AppColors.crimsonAlert;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: toneColor.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                zoneResult.passed
                    ? Icons.verified_user_outlined
                    : Icons.report_problem_outlined,
                size: 18,
                color: toneColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedZone.displayNamePl,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            zoneResult.notePl,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTelemetryBox(
                  title: 'POMIAR',
                  value:
                      '${zoneResult.measuredValue.toStringAsFixed(1)} ${zoneResult.unit}',
                  valueColor: toneColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTelemetryBox(
                  title: 'LIMIT UCI',
                  value:
                      '<= ${zoneResult.limitValue.toStringAsFixed(1)} ${zoneResult.unit}',
                  valueColor: AppColors.textPrimary,
                ),
              ),
              if (scan != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTelemetryBox(
                    title: 'GĘSTOŚĆ X-RAY',
                    value: scan.xrayMetalDensityScore.toStringAsFixed(2),
                    valueColor: AppColors.cyanAccent,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBox({
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STREFY KONTROLI RENTGENOWSKIEJ',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          for (final zone in _primaryZones) ...[
            _buildZoneTile(zone),
            if (zone != _primaryZones.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneTile(EquipmentInspectionZone zone) {
    final result = _zoneResultFor(zone);
    final bool isSelected = _selectedZone == zone;
    final Color statusColor =
        result.passed ? AppColors.statusSuccess : AppColors.crimsonAlert;

    return Material(
      color: isSelected
          ? AppColors.background
          : AppColors.background.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _selectedZone = zone),
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.accentBlue.withValues(alpha: 0.08),
        focusColor: AppColors.goldAccent.withValues(alpha: 0.16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.cyanAccent.withValues(alpha: 0.6)
                  : statusColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                result.passed
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
                size: 18,
                color: statusColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _shortZoneLabel(zone),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${result.measuredValue.toStringAsFixed(1)} ${result.unit} (limit ${result.limitValue.toStringAsFixed(1)} ${result.unit})',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  result.passed ? 'UCI OK' : 'ALARM',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortZoneLabel(EquipmentInspectionZone zone) {
    switch (zone) {
      case EquipmentInspectionZone.bottomBracketShell:
        return 'Suport (mufa suportowa)';
      case EquipmentInspectionZone.seatTubeAndBattery:
        return 'Rura podsiodłowa i sztyca';
      case EquipmentInspectionZone.rearHubMotorCheck:
        return 'Piasty i tylny napęd';
      case EquipmentInspectionZone.handlebarBrakeLevers:
        return 'Kokpit i klamki kierownicy';
      case EquipmentInspectionZone.ttExtensionLength:
        return 'Kokpit i przedłużki TT';
      default:
        return zone.displayNamePl;
    }
  }

  Widget _buildFooter(bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 20,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Text(
            _canProceedToStart
                ? 'Rower dopuszczony do startu przez komisarza UCI.'
                : 'Wymagana korekta przed dopuszczeniem do startu.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: _canProceedToStart
                  ? AppColors.statusSuccess
                  : AppColors.amberWarning,
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _XrayPillButton(
                label: 'Zamknij',
                icon: Icons.close_rounded,
                onPressed: _handleDismiss,
              ),
              _XrayPrimaryButton(
                label: 'Dopuść do startu',
                icon: Icons.flag_rounded,
                accentColor: AppColors.statusSuccess,
                onPressed: _canProceedToStart ? _handleFinishStart : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter renderujący rentgenowski przekrój roweru szosowego/TT,
/// siatkę kalibracyjną, wiązkę skanera X-Ray, zielone znaczniki zgodności UCI
/// oraz pulsujący alarm w strefie kokpitu.
class UciBikeXrayScannerPainter extends CustomPainter {
  final double scanProgress;
  final bool isScanning;
  final double alarmPulse;
  final EquipmentInspectionZone selectedZone;
  final bool bottomBracketCompliant;
  final bool seatTubeCompliant;
  final bool hubsCompliant;
  final bool cockpitCompliant;
  final double leverTiltDeg;
  final bool isTimeTrialSetup;

  const UciBikeXrayScannerPainter({
    required this.scanProgress,
    required this.isScanning,
    required this.alarmPulse,
    required this.selectedZone,
    required this.bottomBracketCompliant,
    required this.seatTubeCompliant,
    required this.hubsCompliant,
    required this.cockpitCompliant,
    required this.leverTiltDeg,
    required this.isTimeTrialSetup,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawCalibrationGrid(canvas, size);
    _drawBicycleXraySilhouette(canvas, size);
    _drawScanBeam(canvas, size);
    _drawZoneMarkers(canvas, size);
  }

  void _drawCalibrationGrid(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;
    final majorPaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.14)
      ..strokeWidth = 1.0;

    const double step = 24.0;
    for (double x = 0; x <= size.width; x += step) {
      final bool isMajor = ((x / step).round() % 4) == 0;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }
    for (double y = 0; y <= size.height; y += step) {
      final bool isMajor = ((y / step).round() % 4) == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  void _drawBicycleXraySilhouette(Canvas canvas, Size size) {
    final rearHub = Offset(size.width * 0.23, size.height * 0.66);
    final frontHub = Offset(size.width * 0.77, size.height * 0.66);
    final bb = Offset(size.width * 0.45, size.height * 0.67);
    final seatCluster = Offset(size.width * 0.39, size.height * 0.43);
    final saddleCenter = Offset(size.width * 0.36, size.height * 0.32);
    final headTop = Offset(size.width * 0.66, size.height * 0.36);
    final headBottom = Offset(size.width * 0.68, size.height * 0.44);
    final stemEnd = Offset(size.width * 0.72, size.height * 0.33);
    final wheelRadius = math.min(size.width * 0.14, size.height * 0.25);

    // Zewnętrzna poświata rentgenowska rur
    final glowPaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.18)
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Wewnętrzne ścianki karbonowe X-Ray
    final framePaint = Paint()
      ..color = AppColors.accentBlue.withValues(alpha: 0.85)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final innerCorePaint = Paint()
      ..color = AppColors.cyanAccent.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Koła i szprychy
    for (final hub in [rearHub, frontHub]) {
      canvas.drawCircle(hub, wheelRadius, glowPaint);
      canvas.drawCircle(hub, wheelRadius, framePaint);
      canvas.drawCircle(hub, wheelRadius * 0.82, innerCorePaint);
      for (int i = 0; i < 12; i++) {
        final angle = (i * math.pi) / 6;
        final spokeEnd = Offset(
          hub.dx + math.cos(angle) * wheelRadius * 0.82,
          hub.dy + math.sin(angle) * wheelRadius * 0.82,
        );
        canvas.drawLine(
          hub,
          spokeEnd,
          Paint()
            ..color = AppColors.accentBlue.withValues(alpha: 0.25)
            ..strokeWidth = 1.0,
        );
      }
      // Piasta rentgenowska
      canvas.drawCircle(
        hub,
        9.0,
        Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.55),
      );
    }

    // Geometria ramy
    final frameSegments = [
      [rearHub, bb],
      [rearHub, seatCluster],
      [bb, seatCluster],
      [bb, headBottom],
      [seatCluster, headTop],
      [headTop, headBottom],
      [headBottom, frontHub],
      [seatCluster, saddleCenter],
      [headTop, stemEnd],
    ];

    for (final seg in frameSegments) {
      canvas.drawLine(seg[0], seg[1], glowPaint);
      canvas.drawLine(seg[0], seg[1], framePaint);
      canvas.drawLine(seg[0], seg[1], innerCorePaint);
    }

    // Siodełko
    canvas.drawLine(
      Offset(saddleCenter.dx - 24, saddleCenter.dy),
      Offset(saddleCenter.dx + 20, saddleCenter.dy),
      framePaint,
    );

    // Mufa suportowa i tarcza korby
    canvas.drawCircle(
      bb,
      18,
      Paint()
        ..color = AppColors.cyanAccent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
    canvas.drawCircle(
      bb,
      8,
      Paint()..color = AppColors.cyanAccent.withValues(alpha: 0.7),
    );

    // Kokpit: baranek szosowy + pochylona klamka (lub lemondka TT)
    final cockpitPaint = Paint()
      ..color = cockpitCompliant
          ? AppColors.cyanAccent.withValues(alpha: 0.9)
          : AppColors.crimsonAlert
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dropArcRect = Rect.fromCircle(
      center: Offset(stemEnd.dx + 8, stemEnd.dy + 16),
      radius: 16,
    );
    canvas.drawArc(dropArcRect, -math.pi / 2, math.pi * 1.15, false, cockpitPaint);

    // Klamka hamulca (wizualizacja odchylenia do wewnątrz/góry)
    final double tiltRad = (leverTiltDeg.clamp(-25, 25)) * math.pi / 180.0;
    final leverBase = Offset(stemEnd.dx + 22, stemEnd.dy + 6);
    final leverTip = Offset(
      leverBase.dx + math.cos(-0.4 + tiltRad) * 18,
      leverBase.dy - math.sin(0.8 + tiltRad) * 16,
    );
    canvas.drawLine(leverBase, leverTip, cockpitPaint);

    if (isTimeTrialSetup) {
      canvas.drawLine(
        stemEnd,
        Offset(stemEnd.dx + 44, stemEnd.dy - 6),
        cockpitPaint,
      );
    }
  }

  void _drawScanBeam(Canvas canvas, Size size) {
    if (!isScanning && scanProgress >= 1.0) return;

    final double beamX = size.width * scanProgress;
    final Rect trailRect = Rect.fromLTWH(
      math.max(0.0, beamX - 54),
      0,
      math.min(54, beamX),
      size.height,
    );

    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          AppColors.cyanAccent.withValues(alpha: 0.24),
        ],
      ).createShader(trailRect);

    canvas.drawRect(trailRect, trailPaint);

    final beamPaint = Paint()
      ..color = AppColors.cyanAccent
      ..strokeWidth = 2.2;
    canvas.drawLine(
      Offset(beamX, 0),
      Offset(beamX, size.height),
      beamPaint,
    );
  }

  void _drawZoneMarkers(Canvas canvas, Size size) {
    _drawReticle(
      canvas,
      center: Offset(size.width * 0.45, size.height * 0.67),
      compliant: bottomBracketCompliant,
      selected: selectedZone == EquipmentInspectionZone.bottomBracketShell,
      tag: 'SUPORT',
    );
    _drawReticle(
      canvas,
      center: Offset(size.width * 0.39, size.height * 0.43),
      compliant: seatTubeCompliant,
      selected: selectedZone == EquipmentInspectionZone.seatTubeAndBattery,
      tag: 'RURA PODSIODŁOWA',
    );
    _drawReticle(
      canvas,
      center: Offset(size.width * 0.23, size.height * 0.66),
      compliant: hubsCompliant,
      selected: selectedZone == EquipmentInspectionZone.rearHubMotorCheck,
      tag: 'PIASTA',
    );
    _drawReticle(
      canvas,
      center: Offset(size.width * 0.70, size.height * 0.31),
      compliant: cockpitCompliant,
      selected: selectedZone == EquipmentInspectionZone.handlebarBrakeLevers ||
          selectedZone == EquipmentInspectionZone.ttExtensionLength,
      tag: cockpitCompliant ? 'KOKPIT OK' : 'ALARM ${leverTiltDeg.toStringAsFixed(1)}°',
    );
  }

  void _drawReticle(
    Canvas canvas, {
    required Offset center,
    required bool compliant,
    required bool selected,
    required String tag,
  }) {
    final Color color =
        compliant ? AppColors.statusSuccess : AppColors.crimsonAlert;
    final double pulseScale =
        compliant ? 1.0 : (1.0 + 0.18 * alarmPulse);
    final double radius = (selected ? 20.0 : 15.0) * pulseScale;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2.2 : 1.5,
    );

    if (selected) {
      canvas.drawCircle(
        center,
        radius + 5,
        Paint()
          ..color = AppColors.goldAccent.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: tag,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelOffset = Offset(
      center.dx - textPainter.width / 2,
      center.dy - radius - 14,
    );
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant UciBikeXrayScannerPainter oldDelegate) {
    return oldDelegate.scanProgress != scanProgress ||
        oldDelegate.isScanning != isScanning ||
        oldDelegate.alarmPulse != alarmPulse ||
        oldDelegate.selectedZone != selectedZone ||
        oldDelegate.bottomBracketCompliant != bottomBracketCompliant ||
        oldDelegate.seatTubeCompliant != seatTubeCompliant ||
        oldDelegate.hubsCompliant != hubsCompliant ||
        oldDelegate.cockpitCompliant != cockpitCompliant ||
        oldDelegate.leverTiltDeg != leverTiltDeg ||
        oldDelegate.isTimeTrialSetup != isTimeTrialSetup;
  }
}

class _XrayActionIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _XrayActionIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  State<_XrayActionIconButton> createState() => _XrayActionIconButtonState();
}

class _XrayActionIconButtonState extends State<_XrayActionIconButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    return Tooltip(
      message: widget.tooltip,
      child: FocusableActionDetector(
        enabled: enabled,
        onShowHoverHighlight: (v) => setState(() => _hovered = v),
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        child: Material(
          color: _hovered
              ? AppColors.surfaceLight
              : AppColors.surfaceLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _focused
                      ? AppColors.goldAccent
                      : AppColors.cardBorder,
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
      ),
    );
  }
}

class _XrayPillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  const _XrayPillButton({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  @override
  State<_XrayPillButton> createState() => _XrayPillButtonState();
}

class _XrayPillButtonState extends State<_XrayPillButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: Material(
        color: _hovered ? AppColors.surfaceLight : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (_hovered ? AppColors.accentBlue : AppColors.cardBorder),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.45),
                    ),
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

class _XrayPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onPressed;

  const _XrayPrimaryButton({
    required this.label,
    required this.icon,
    required this.accentColor,
    this.onPressed,
  });

  @override
  State<_XrayPrimaryButton> createState() => _XrayPrimaryButtonState();
}

class _XrayPrimaryButtonState extends State<_XrayPrimaryButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null;
    final Color base = enabled
        ? widget.accentColor
        : AppColors.surfaceLight;

    return FocusableActionDetector(
      enabled: enabled,
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      child: Material(
        color: enabled
            ? base.withValues(
                alpha: _pressed ? 0.95 : (_hovered ? 0.30 : 0.20),
              )
            : AppColors.surfaceLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _focused
                    ? AppColors.goldAccent
                    : (enabled ? base : AppColors.cardBorder),
                width: _focused ? 1.6 : 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: 16,
                  color: enabled
                      ? (_pressed ? AppColors.background : widget.accentColor)
                      : AppColors.textSecondary.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: enabled
                          ? (_pressed ? AppColors.background : AppColors.textPrimary)
                          : AppColors.textSecondary.withValues(alpha: 0.45),
                    ),
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
