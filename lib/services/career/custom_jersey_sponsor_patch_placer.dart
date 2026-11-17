// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';

/// Rola logotypu / naszywki na stroju kolarskim.
enum SponsorPatchRole {
  primarySponsor('Sponsor Główny'),
  secondarySponsor('Sponsor Drugorzędny'),
  bikeManufacturer('Producent Roweru'),
  nationalFlag('Flaga Narodowa');

  final String label;
  const SponsorPatchRole(this.label);

  String toJson() => name;

  static SponsorPatchRole fromJson(String value) {
    return SponsorPatchRole.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorPatchRole.primarySponsor,
    );
  }
}

/// Kształt herbu / podkładki logotypu sponsora.
enum SponsorCrestShape {
  shield('Tarcza'),
  hexagon('Heksagon'),
  circle('Okrąg'),
  diamond('Romb'),
  banner('Wstęga');

  final String label;
  const SponsorCrestShape(this.label);

  String toJson() => name;

  static SponsorCrestShape fromJson(String value) {
    return SponsorCrestShape.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorCrestShape.shield,
    );
  }
}

/// 8 precyzyjnych stref rozmieszczenia logotypów na koszulce, kołnierzyku i spodenkach.
enum SponsorPatchZone {
  chestMain(
    'Klatka Piersiowa (Herb Główny)',
    'Klatka',
    SponsorPatchRole.primarySponsor,
    Offset(0.50, 0.28),
    isFrontOnly: true,
  ),
  backMain(
    'Plecy (Herb Główny)',
    'Plecy',
    SponsorPatchRole.primarySponsor,
    Offset(0.50, 0.27),
    isBackOnly: true,
  ),
  leftSleeve(
    'Lewy Rękawek (Sponsor II)',
    'Lewy Rękaw',
    SponsorPatchRole.secondarySponsor,
    Offset(0.15, 0.255),
    isSleeve: true,
  ),
  rightSleeve(
    'Prawy Rękawek (Sponsor II)',
    'Prawy Rękaw',
    SponsorPatchRole.secondarySponsor,
    Offset(0.85, 0.255),
    isSleeve: true,
  ),
  leftBibSide(
    'Lewy Panel Spodenek (Sponsor II)',
    'Lewa Nogawka',
    SponsorPatchRole.secondarySponsor,
    Offset(0.325, 0.72),
    isBib: true,
  ),
  rightBibSide(
    'Prawy Panel Spodenek (Sponsor II)',
    'Prawa Nogawka',
    SponsorPatchRole.secondarySponsor,
    Offset(0.675, 0.72),
    isBib: true,
  ),
  collarLeft(
    'Kołnierzyk Lewy (Producent Roweru)',
    'Kołnierz Rower',
    SponsorPatchRole.bikeManufacturer,
    Offset(0.415, 0.115),
    isCollar: true,
  ),
  collarRight(
    'Kołnierzyk Prawy (Flaga Narodowa)',
    'Kołnierz Flaga',
    SponsorPatchRole.nationalFlag,
    Offset(0.585, 0.115),
    isCollar: true,
  );

  final String label;
  final String shortLabel;
  final SponsorPatchRole defaultRole;
  final Offset defaultAnchor;
  final bool isFrontOnly;
  final bool isBackOnly;
  final bool isSleeve;
  final bool isBib;
  final bool isCollar;

  const SponsorPatchZone(
    this.label,
    this.shortLabel,
    this.defaultRole,
    this.defaultAnchor, {
    this.isFrontOnly = false,
    this.isBackOnly = false,
    this.isSleeve = false,
    this.isBib = false,
    this.isCollar = false,
  });

  bool isVisibleInView({required bool isBackView}) {
    if (isFrontOnly && isBackView) return false;
    if (isBackOnly && !isBackView) return false;
    return true;
  }

  String toJson() => name;

  static SponsorPatchZone fromJson(String value) {
    return SponsorPatchZone.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => SponsorPatchZone.chestMain,
    );
  }
}

/// Wektorowa definicja flagi narodowej do rysowania na kołnierzyku i w modelu 3D.
class NationalFlagPalette {
  final String isoCode;
  final String countryName;
  final List<Color> stripeColors;
  final bool isVertical;

  const NationalFlagPalette({
    required this.isoCode,
    required this.countryName,
    required this.stripeColors,
    this.isVertical = false,
  });

  static const List<NationalFlagPalette> catalog = <NationalFlagPalette>[
    NationalFlagPalette(
      isoCode: 'POL',
      countryName: 'Polska',
      stripeColors: <Color>[Color(0xFFFFFFFF), Color(0xFFDC143C)],
    ),
    NationalFlagPalette(
      isoCode: 'BEL',
      countryName: 'Belgia',
      stripeColors: <Color>[Color(0xFF111827), Color(0xFFFACC15), Color(0xFFEF4444)],
      isVertical: true,
    ),
    NationalFlagPalette(
      isoCode: 'FRA',
      countryName: 'Francja',
      stripeColors: <Color>[Color(0xFF1D4ED8), Color(0xFFFFFFFF), Color(0xFFDC2626)],
      isVertical: true,
    ),
    NationalFlagPalette(
      isoCode: 'ITA',
      countryName: 'Włochy',
      stripeColors: <Color>[Color(0xFF16A34A), Color(0xFFFFFFFF), Color(0xFFDC2626)],
      isVertical: true,
    ),
    NationalFlagPalette(
      isoCode: 'NED',
      countryName: 'Holandia',
      stripeColors: <Color>[Color(0xFFAE1C28), Color(0xFFFFFFFF), Color(0xFF21468B)],
    ),
    NationalFlagPalette(
      isoCode: 'ESP',
      countryName: 'Hiszpania',
      stripeColors: <Color>[Color(0xFFAA151B), Color(0xFFF1BF00), Color(0xFFAA151B)],
    ),
    NationalFlagPalette(
      isoCode: 'SLO',
      countryName: 'Słowenia',
      stripeColors: <Color>[Color(0xFFFFFFFF), Color(0xFF1D4ED8), Color(0xFFDC2626)],
    ),
    NationalFlagPalette(
      isoCode: 'DEN',
      countryName: 'Dania',
      stripeColors: <Color>[Color(0xFFC8102E), Color(0xFFFFFFFF), Color(0xFFC8102E)],
    ),
    NationalFlagPalette(
      isoCode: 'GBR',
      countryName: 'Wielka Brytania',
      stripeColors: <Color>[Color(0xFF012169), Color(0xFFFFFFFF), Color(0xFFC8102E)],
    ),
    NationalFlagPalette(
      isoCode: 'GER',
      countryName: 'Niemcy',
      stripeColors: <Color>[Color(0xFF111827), Color(0xFFDC2626), Color(0xFFFACC15)],
    ),
    NationalFlagPalette(
      isoCode: 'COL',
      countryName: 'Kolumbia',
      stripeColors: <Color>[Color(0xFFFCD116), Color(0xFF003893), Color(0xFFCE1126)],
    ),
    NationalFlagPalette(
      isoCode: 'USA',
      countryName: 'USA',
      stripeColors: <Color>[Color(0xFF0A3161), Color(0xFFFFFFFF), Color(0xFFB31942)],
    ),
  ];

  static NationalFlagPalette resolve(String isoCode) {
    final normalized = isoCode.trim().toUpperCase();
    return catalog.firstWhere(
      (f) => f.isoCode == normalized,
      orElse: () => catalog.first,
    );
  }
}

/// Specyfikacja pojedynczej naszywki / logotypu na stroju kolarskim.
class JerseySponsorPatchSpec {
  final SponsorPatchZone zone;
  final SponsorPatchRole role;
  final String label;
  final SponsorCrestShape crestShape;
  final double offsetX;
  final double offsetY;
  final double scale;
  final double rotationDeg;
  final String backgroundColorHex;
  final String foregroundColorHex;
  final String countryIso;
  final bool isVisible;

  const JerseySponsorPatchSpec({
    required this.zone,
    required this.role,
    required this.label,
    this.crestShape = SponsorCrestShape.shield,
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scale = 1.0,
    this.rotationDeg = 0.0,
    this.backgroundColorHex = '#181B22',
    this.foregroundColorHex = '#FFFFFF',
    this.countryIso = 'POL',
    this.isVisible = true,
  });

  JerseySponsorPatchSpec copyWith({
    SponsorPatchZone? zone,
    SponsorPatchRole? role,
    String? label,
    SponsorCrestShape? crestShape,
    double? offsetX,
    double? offsetY,
    double? scale,
    double? rotationDeg,
    String? backgroundColorHex,
    String? foregroundColorHex,
    String? countryIso,
    bool? isVisible,
  }) {
    return JerseySponsorPatchSpec(
      zone: zone ?? this.zone,
      role: role ?? this.role,
      label: label ?? this.label,
      crestShape: crestShape ?? this.crestShape,
      offsetX: (offsetX ?? this.offsetX).clamp(-0.12, 0.12),
      offsetY: (offsetY ?? this.offsetY).clamp(-0.12, 0.12),
      scale: (scale ?? this.scale).clamp(0.60, 1.45),
      rotationDeg: (rotationDeg ?? this.rotationDeg).clamp(-25.0, 25.0),
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      foregroundColorHex: foregroundColorHex ?? this.foregroundColorHex,
      countryIso: countryIso ?? this.countryIso,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'zone': zone.toJson(),
      'role': role.toJson(),
      'label': label,
      'crestShape': crestShape.toJson(),
      'offsetX': offsetX,
      'offsetY': offsetY,
      'scale': scale,
      'rotationDeg': rotationDeg,
      'backgroundColorHex': backgroundColorHex,
      'foregroundColorHex': foregroundColorHex,
      'countryIso': countryIso,
      'isVisible': isVisible,
    };
  }

  factory JerseySponsorPatchSpec.fromJson(Map<String, dynamic> json) {
    final zone = SponsorPatchZone.fromJson(json['zone'] as String? ?? 'chestMain');
    return JerseySponsorPatchSpec(
      zone: zone,
      role: SponsorPatchRole.fromJson(json['role'] as String? ?? zone.defaultRole.name),
      label: json['label'] as String? ?? '',
      crestShape: SponsorCrestShape.fromJson(json['crestShape'] as String? ?? 'shield'),
      offsetX: ((json['offsetX'] as num?)?.toDouble() ?? 0.0).clamp(-0.12, 0.12),
      offsetY: ((json['offsetY'] as num?)?.toDouble() ?? 0.0).clamp(-0.12, 0.12),
      scale: ((json['scale'] as num?)?.toDouble() ?? 1.0).clamp(0.60, 1.45),
      rotationDeg: ((json['rotationDeg'] as num?)?.toDouble() ?? 0.0).clamp(-25.0, 25.0),
      backgroundColorHex: json['backgroundColorHex'] as String? ?? '#181B22',
      foregroundColorHex: json['foregroundColorHex'] as String? ?? '#FFFFFF',
      countryIso: json['countryIso'] as String? ?? 'POL',
      isVisible: json['isVisible'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is JerseySponsorPatchSpec &&
        other.zone == zone &&
        other.role == role &&
        other.label == label &&
        other.crestShape == crestShape &&
        other.offsetX == offsetX &&
        other.offsetY == offsetY &&
        other.scale == scale &&
        other.rotationDeg == rotationDeg &&
        other.backgroundColorHex == backgroundColorHex &&
        other.foregroundColorHex == foregroundColorHex &&
        other.countryIso == countryIso &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode => Object.hash(
        zone,
        role,
        label,
        crestShape,
        offsetX,
        offsetY,
        scale,
        rotationDeg,
        backgroundColorHex,
        foregroundColorHex,
        countryIso,
        isVisible,
      );
}

/// Kompletny układ rozmieszczenia logotypów i flagi na stroju drużyny.
class JerseySponsorPatchLayout {
  final String teamId;
  final Map<SponsorPatchZone, JerseySponsorPatchSpec> patches;
  final String updatedAtIso;

  const JerseySponsorPatchLayout({
    required this.teamId,
    required this.patches,
    required this.updatedAtIso,
  });

  factory JerseySponsorPatchLayout.defaultForTeam({
    String teamId = 'player_team',
    String primarySponsor = 'VISMA',
    String secondarySponsor = 'LEASE A BIKE',
    String bikeBrand = 'CERVÉLO',
    String countryIso = 'POL',
    String accentColorHex = '#D4AF37',
    String foregroundColorHex = '#FFFFFF',
  }) {
    final cleanPrimary = primarySponsor.trim().isEmpty ? 'TEAM' : primarySponsor.trim();
    final cleanSecondary = secondarySponsor.trim().isEmpty ? 'PARTNER' : secondarySponsor.trim();
    final cleanBike = bikeBrand.trim().isEmpty ? 'PRO BIKE' : bikeBrand.trim();
    final cleanIso = countryIso.trim().isEmpty ? 'POL' : countryIso.trim().toUpperCase();

    return JerseySponsorPatchLayout(
      teamId: teamId,
      updatedAtIso: DateTime.utc(2026, 1, 1).toIso8601String(),
      patches: Map<SponsorPatchZone, JerseySponsorPatchSpec>.unmodifiable({
        SponsorPatchZone.chestMain: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.chestMain,
          role: SponsorPatchRole.primarySponsor,
          label: cleanPrimary,
          crestShape: SponsorCrestShape.shield,
          scale: 1.0,
          backgroundColorHex: accentColorHex,
          foregroundColorHex: foregroundColorHex,
        ),
        SponsorPatchZone.backMain: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.backMain,
          role: SponsorPatchRole.primarySponsor,
          label: cleanPrimary,
          crestShape: SponsorCrestShape.shield,
          scale: 0.95,
          backgroundColorHex: accentColorHex,
          foregroundColorHex: foregroundColorHex,
        ),
        SponsorPatchZone.leftSleeve: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.leftSleeve,
          role: SponsorPatchRole.secondarySponsor,
          label: cleanSecondary,
          crestShape: SponsorCrestShape.banner,
          scale: 0.95,
          rotationDeg: -14.0,
          backgroundColorHex: '#222630',
          foregroundColorHex: foregroundColorHex,
        ),
        SponsorPatchZone.rightSleeve: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.rightSleeve,
          role: SponsorPatchRole.secondarySponsor,
          label: cleanSecondary,
          crestShape: SponsorCrestShape.banner,
          scale: 0.95,
          rotationDeg: 14.0,
          backgroundColorHex: '#222630',
          foregroundColorHex: foregroundColorHex,
        ),
        SponsorPatchZone.leftBibSide: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.leftBibSide,
          role: SponsorPatchRole.secondarySponsor,
          label: cleanSecondary,
          crestShape: SponsorCrestShape.banner,
          scale: 1.0,
          rotationDeg: -8.0,
          backgroundColorHex: accentColorHex,
          foregroundColorHex: '#111317',
        ),
        SponsorPatchZone.rightBibSide: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.rightBibSide,
          role: SponsorPatchRole.secondarySponsor,
          label: cleanSecondary,
          crestShape: SponsorCrestShape.banner,
          scale: 1.0,
          rotationDeg: 8.0,
          backgroundColorHex: accentColorHex,
          foregroundColorHex: '#111317',
        ),
        SponsorPatchZone.collarLeft: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.collarLeft,
          role: SponsorPatchRole.bikeManufacturer,
          label: cleanBike,
          crestShape: SponsorCrestShape.hexagon,
          scale: 0.95,
          backgroundColorHex: '#181B22',
          foregroundColorHex: '#D4AF37',
        ),
        SponsorPatchZone.collarRight: JerseySponsorPatchSpec(
          zone: SponsorPatchZone.collarRight,
          role: SponsorPatchRole.nationalFlag,
          label: cleanIso,
          crestShape: SponsorCrestShape.banner,
          scale: 0.95,
          countryIso: cleanIso,
          backgroundColorHex: '#181B22',
          foregroundColorHex: '#FFFFFF',
        ),
      }),
    );
  }

  JerseySponsorPatchSpec patchFor(SponsorPatchZone zone) {
    return patches[zone] ??
        JerseySponsorPatchSpec(
          zone: zone,
          role: zone.defaultRole,
          label: zone.shortLabel,
        );
  }

  JerseySponsorPatchLayout withUpdatedPatch(
    JerseySponsorPatchSpec updated, {
    DateTime? timestamp,
  }) {
    final nextMap = Map<SponsorPatchZone, JerseySponsorPatchSpec>.from(patches);
    nextMap[updated.zone] = updated;
    return JerseySponsorPatchLayout(
      teamId: teamId,
      patches: Map<SponsorPatchZone, JerseySponsorPatchSpec>.unmodifiable(nextMap),
      updatedAtIso: (timestamp ?? DateTime.now().toUtc()).toIso8601String(),
    );
  }

  /// Synchronizuje symetrycznie prawy rękawek i prawy panel spodenek względem lewej strony.
  JerseySponsorPatchLayout mirrorSleevesAndBibs({DateTime? timestamp}) {
    final leftSleeve = patchFor(SponsorPatchZone.leftSleeve);
    final leftBib = patchFor(SponsorPatchZone.leftBibSide);
    final nextMap = Map<SponsorPatchZone, JerseySponsorPatchSpec>.from(patches);

    nextMap[SponsorPatchZone.rightSleeve] = leftSleeve.copyWith(
      zone: SponsorPatchZone.rightSleeve,
      offsetX: -leftSleeve.offsetX,
      rotationDeg: -leftSleeve.rotationDeg,
    );
    nextMap[SponsorPatchZone.rightBibSide] = leftBib.copyWith(
      zone: SponsorPatchZone.rightBibSide,
      offsetX: -leftBib.offsetX,
      rotationDeg: -leftBib.rotationDeg,
    );

    return JerseySponsorPatchLayout(
      teamId: teamId,
      patches: Map<SponsorPatchZone, JerseySponsorPatchSpec>.unmodifiable(nextMap),
      updatedAtIso: (timestamp ?? DateTime.now().toUtc()).toIso8601String(),
    );
  }

  JerseySponsorPatchLayout resetZone(
    SponsorPatchZone zone, {
    String primarySponsor = 'VISMA',
    String secondarySponsor = 'LEASE A BIKE',
    String bikeBrand = 'CERVÉLO',
    String countryIso = 'POL',
    DateTime? timestamp,
  }) {
    final defaults = JerseySponsorPatchLayout.defaultForTeam(
      teamId: teamId,
      primarySponsor: primarySponsor,
      secondarySponsor: secondarySponsor,
      bikeBrand: bikeBrand,
      countryIso: countryIso,
    );
    return withUpdatedPatch(defaults.patchFor(zone), timestamp: timestamp);
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'teamId': teamId,
      'updatedAtIso': updatedAtIso,
      'patches': <String, dynamic>{
        for (final entry in patches.entries) entry.key.toJson(): entry.value.toJson(),
      },
    };
  }

  factory JerseySponsorPatchLayout.fromJson(Map<String, dynamic> json) {
    final rawPatches = json['patches'] as Map<String, dynamic>? ?? const <String, dynamic>{};
    final parsed = <SponsorPatchZone, JerseySponsorPatchSpec>{};
    for (final entry in rawPatches.entries) {
      final zone = SponsorPatchZone.fromJson(entry.key);
      if (entry.value is Map<String, dynamic>) {
        parsed[zone] = JerseySponsorPatchSpec.fromJson(entry.value as Map<String, dynamic>);
      }
    }
    return JerseySponsorPatchLayout(
      teamId: json['teamId'] as String? ?? 'player_team',
      updatedAtIso: json['updatedAtIso'] as String? ?? DateTime.utc(2026, 1, 1).toIso8601String(),
      patches: Map<SponsorPatchZone, JerseySponsorPatchSpec>.unmodifiable(parsed),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JerseySponsorPatchLayout || other.teamId != teamId) return false;
    if (other.patches.length != patches.length) return false;
    for (final entry in patches.entries) {
      if (other.patches[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(teamId, Object.hashAll(patches.values));
}

/// Lekki deskryptor dziedziczony automatycznie przez modele 3D kolarzy w silniku wyścigu (`Peloton3dCanvasEngine`).
class Race3dJerseyPatchDescriptor {
  final String teamId;
  final Color chestCrestColor;
  final Color chestTextColor;
  final String chestLabel;
  final SponsorCrestShape chestShape;
  final double chestScale;
  final bool showChestPatch;

  final Color backCrestColor;
  final String backLabel;
  final bool showBackPatch;

  final Color sleevePatchColor;
  final String sleeveLabel;
  final bool showSleevePatches;

  final Color bibSidePanelColor;
  final String bibSideLabel;
  final bool showBibSidePatches;

  final Color collarBikeColor;
  final String collarBikeLabel;
  final bool showCollarBikeLogo;

  final String collarCountryIso;
  final List<Color> collarFlagColors;
  final bool collarFlagVertical;
  final bool showCollarFlag;

  const Race3dJerseyPatchDescriptor({
    required this.teamId,
    required this.chestCrestColor,
    required this.chestTextColor,
    required this.chestLabel,
    required this.chestShape,
    required this.chestScale,
    required this.showChestPatch,
    required this.backCrestColor,
    required this.backLabel,
    required this.showBackPatch,
    required this.sleevePatchColor,
    required this.sleeveLabel,
    required this.showSleevePatches,
    required this.bibSidePanelColor,
    required this.bibSideLabel,
    required this.showBibSidePatches,
    required this.collarBikeColor,
    required this.collarBikeLabel,
    required this.showCollarBikeLogo,
    required this.collarCountryIso,
    required this.collarFlagColors,
    required this.collarFlagVertical,
    required this.showCollarFlag,
  });

  bool get hasVisiblePatches =>
      showChestPatch ||
      showBackPatch ||
      showSleevePatches ||
      showBibSidePatches ||
      showCollarBikeLogo ||
      showCollarFlag;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'teamId': teamId,
      'chestCrestColor': chestCrestColor.toARGB32(),
      'chestTextColor': chestTextColor.toARGB32(),
      'chestLabel': chestLabel,
      'chestShape': chestShape.toJson(),
      'chestScale': chestScale,
      'showChestPatch': showChestPatch,
      'backCrestColor': backCrestColor.toARGB32(),
      'backLabel': backLabel,
      'showBackPatch': showBackPatch,
      'sleevePatchColor': sleevePatchColor.toARGB32(),
      'sleeveLabel': sleeveLabel,
      'showSleevePatches': showSleevePatches,
      'bibSidePanelColor': bibSidePanelColor.toARGB32(),
      'bibSideLabel': bibSideLabel,
      'showBibSidePatches': showBibSidePatches,
      'collarBikeColor': collarBikeColor.toARGB32(),
      'collarBikeLabel': collarBikeLabel,
      'showCollarBikeLogo': showCollarBikeLogo,
      'collarCountryIso': collarCountryIso,
      'collarFlagColors': collarFlagColors.map((c) => c.toARGB32()).toList(),
      'collarFlagVertical': collarFlagVertical,
      'showCollarFlag': showCollarFlag,
    };
  }

  factory Race3dJerseyPatchDescriptor.fromJson(Map<String, dynamic> json) {
    final flagInts = (json['collarFlagColors'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => Color((e as num).toInt()))
        .toList();
    return Race3dJerseyPatchDescriptor(
      teamId: json['teamId'] as String? ?? 'player_team',
      chestCrestColor: Color((json['chestCrestColor'] as num?)?.toInt() ?? 0xFFD4AF37),
      chestTextColor: Color((json['chestTextColor'] as num?)?.toInt() ?? 0xFFFFFFFF),
      chestLabel: json['chestLabel'] as String? ?? 'TEAM',
      chestShape: SponsorCrestShape.fromJson(json['chestShape'] as String? ?? 'shield'),
      chestScale: (json['chestScale'] as num?)?.toDouble() ?? 1.0,
      showChestPatch: json['showChestPatch'] as bool? ?? true,
      backCrestColor: Color((json['backCrestColor'] as num?)?.toInt() ?? 0xFFD4AF37),
      backLabel: json['backLabel'] as String? ?? 'TEAM',
      showBackPatch: json['showBackPatch'] as bool? ?? true,
      sleevePatchColor: Color((json['sleevePatchColor'] as num?)?.toInt() ?? 0xFF222630),
      sleeveLabel: json['sleeveLabel'] as String? ?? 'PARTNER',
      showSleevePatches: json['showSleevePatches'] as bool? ?? true,
      bibSidePanelColor: Color((json['bibSidePanelColor'] as num?)?.toInt() ?? 0xFFD4AF37),
      bibSideLabel: json['bibSideLabel'] as String? ?? 'PARTNER',
      showBibSidePatches: json['showBibSidePatches'] as bool? ?? true,
      collarBikeColor: Color((json['collarBikeColor'] as num?)?.toInt() ?? 0xFFD4AF37),
      collarBikeLabel: json['collarBikeLabel'] as String? ?? 'PRO BIKE',
      showCollarBikeLogo: json['showCollarBikeLogo'] as bool? ?? true,
      collarCountryIso: json['collarCountryIso'] as String? ?? 'POL',
      collarFlagColors: flagInts.isNotEmpty
          ? flagInts
          : const <Color>[Color(0xFFFFFFFF), Color(0xFFDC143C)],
      collarFlagVertical: json['collarFlagVertical'] as bool? ?? false,
      showCollarFlag: json['showCollarFlag'] as bool? ?? true,
    );
  }
}

/// Raport walidacji przepisów UCI oraz czytelności logotypów na stroju.
class PatchPlacementValidationReport {
  final bool isValid;
  final List<String> warnings;
  final int activePatchesCount;

  const PatchPlacementValidationReport({
    required this.isValid,
    required this.warnings,
    required this.activePatchesCount,
  });
}

/// Precyzyjny rozmieszczacz logotypów sponsorów, producenta roweru i flagi narodowej
/// z automatycznym dziedziczeniem przez modele 3D w wyścigu.
class CustomJerseySponsorPatchPlacer {
  const CustomJerseySponsorPatchPlacer();

  static Color parseHexColor(String hex, {Color fallback = const Color(0xFFD4AF37)}) {
    var clean = hex.trim().replaceAll('#', '');
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    if (clean.length != 8) return fallback;
    final parsed = int.tryParse(clean, radix: 16);
    if (parsed == null) return fallback;
    return Color(parsed);
  }

  /// Wylicza precyzyjną pozycję środka strefy w układzie Canvas (0..width, 0..height).
  static Offset resolveZoneCanvasCenter(
    JerseySponsorPatchSpec spec,
    Size canvasSize,
  ) {
    final anchor = spec.zone.defaultAnchor;
    return Offset(
      (anchor.dx + spec.offsetX) * canvasSize.width,
      (anchor.dy + spec.offsetY) * canvasSize.height,
    );
  }

  /// Wykrywa strefę klikniętą lub wskazaną kursorem na podglądzie stroju.
  static SponsorPatchZone? hitTestZone(
    Offset localPosition,
    Size canvasSize,
    JerseySponsorPatchLayout layout, {
    required bool isBackView,
  }) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return null;
    SponsorPatchZone? bestZone;
    double bestDist = double.infinity;

    for (final zone in SponsorPatchZone.values) {
      if (!zone.isVisibleInView(isBackView: isBackView)) continue;
      final spec = layout.patchFor(zone);
      final center = resolveZoneCanvasCenter(spec, canvasSize);
      final hitRadius = _hitRadiusForZone(zone, canvasSize) * spec.scale;
      final dist = (localPosition - center).distance;
      if (dist <= hitRadius && dist < bestDist) {
        bestDist = dist;
        bestZone = zone;
      }
    }
    return bestZone;
  }

  static double _hitRadiusForZone(SponsorPatchZone zone, Size size) {
    final minDim = math.min(size.width, size.height);
    if (zone == SponsorPatchZone.chestMain || zone == SponsorPatchZone.backMain) {
      return minDim * 0.14;
    }
    if (zone.isCollar) {
      return minDim * 0.065;
    }
    return minDim * 0.095;
  }

  /// Przelicza przesunięcie kursora/palca na bezpieczny znormalizowany offset strefy.
  static JerseySponsorPatchSpec applyDragDelta(
    JerseySponsorPatchSpec spec,
    Offset delta,
    Size canvasSize,
  ) {
    if (canvasSize.width <= 0 || canvasSize.height <= 0) return spec;
    final dx = delta.dx / canvasSize.width;
    final dy = delta.dy / canvasSize.height;
    return spec.copyWith(
      offsetX: spec.offsetX + dx,
      offsetY: spec.offsetY + dy,
    );
  }

  /// Buduje deskryptor dziedziczony automatycznie przez modele 3D w wyścigu.
  static Race3dJerseyPatchDescriptor buildRace3dInheritance(
    JerseySponsorPatchLayout layout,
  ) {
    final chest = layout.patchFor(SponsorPatchZone.chestMain);
    final back = layout.patchFor(SponsorPatchZone.backMain);
    final leftSleeve = layout.patchFor(SponsorPatchZone.leftSleeve);
    final rightSleeve = layout.patchFor(SponsorPatchZone.rightSleeve);
    final leftBib = layout.patchFor(SponsorPatchZone.leftBibSide);
    final rightBib = layout.patchFor(SponsorPatchZone.rightBibSide);
    final collarBike = layout.patchFor(SponsorPatchZone.collarLeft);
    final collarFlag = layout.patchFor(SponsorPatchZone.collarRight);
    final flagPalette = NationalFlagPalette.resolve(collarFlag.countryIso);

    return Race3dJerseyPatchDescriptor(
      teamId: layout.teamId,
      chestCrestColor: parseHexColor(chest.backgroundColorHex),
      chestTextColor: parseHexColor(chest.foregroundColorHex, fallback: Colors.white),
      chestLabel: chest.label,
      chestShape: chest.crestShape,
      chestScale: chest.scale,
      showChestPatch: chest.isVisible && chest.label.trim().isNotEmpty,
      backCrestColor: parseHexColor(back.backgroundColorHex),
      backLabel: back.label,
      showBackPatch: back.isVisible && back.label.trim().isNotEmpty,
      sleevePatchColor: parseHexColor(leftSleeve.backgroundColorHex, fallback: AppColors.surfaceLight),
      sleeveLabel: leftSleeve.label,
      showSleevePatches: (leftSleeve.isVisible || rightSleeve.isVisible) &&
          leftSleeve.label.trim().isNotEmpty,
      bibSidePanelColor: parseHexColor(leftBib.backgroundColorHex),
      bibSideLabel: leftBib.label,
      showBibSidePatches: (leftBib.isVisible || rightBib.isVisible) &&
          leftBib.label.trim().isNotEmpty,
      collarBikeColor: parseHexColor(collarBike.foregroundColorHex),
      collarBikeLabel: collarBike.label,
      showCollarBikeLogo: collarBike.isVisible && collarBike.label.trim().isNotEmpty,
      collarCountryIso: flagPalette.isoCode,
      collarFlagColors: flagPalette.stripeColors,
      collarFlagVertical: flagPalette.isVertical,
      showCollarFlag: collarFlag.isVisible,
    );
  }

  /// Waliduje czytelność oraz zgodność z wytycznymi UCI dot. powierzchni sponsorów.
  static PatchPlacementValidationReport validateLayout(
    JerseySponsorPatchLayout layout,
  ) {
    final warnings = <String>[];
    int visibleCount = 0;

    for (final zone in SponsorPatchZone.values) {
      final spec = layout.patchFor(zone);
      if (spec.isVisible) visibleCount++;
    }

    final chest = layout.patchFor(SponsorPatchZone.chestMain);
    final back = layout.patchFor(SponsorPatchZone.backMain);
    if (!chest.isVisible || !back.isVisible) {
      warnings.add('Sponsor główny powinien być widoczny na klatce piersiowej oraz na plecach.');
    }
    if (chest.scale > 1.38) {
      warnings.add('Herb na klatce piersiowej przekracza zalecany rozmiar UCI (skala > 1.38).');
    }
    final bike = layout.patchFor(SponsorPatchZone.collarLeft);
    final flag = layout.patchFor(SponsorPatchZone.collarRight);
    if (bike.isVisible && flag.isVisible) {
      final dist = (bike.zone.defaultAnchor +
              Offset(bike.offsetX, bike.offsetY) -
              (flag.zone.defaultAnchor + Offset(flag.offsetX, flag.offsetY)))
          .distance;
      if (dist < 0.08) {
        warnings.add('Logo producenta roweru i flaga na kołnierzyku są zbyt blisko siebie.');
      }
    }

    return PatchPlacementValidationReport(
      isValid: warnings.isEmpty,
      warnings: List<String>.unmodifiable(warnings),
      activePatchesCount: visibleCount,
    );
  }
}

/// Stan Riverpod przechowujący układ naszywek oraz gotowe deskryptory 3D dla wyścigu.
class CustomJerseySponsorPatchState {
  final JerseySponsorPatchLayout activeLayout;
  final Map<String, Race3dJerseyPatchDescriptor> inheritedRace3dByTeam;

  const CustomJerseySponsorPatchState({
    required this.activeLayout,
    required this.inheritedRace3dByTeam,
  });

  factory CustomJerseySponsorPatchState.initial() {
    final defaultLayout = JerseySponsorPatchLayout.defaultForTeam();
    final descriptor = CustomJerseySponsorPatchPlacer.buildRace3dInheritance(defaultLayout);
    return CustomJerseySponsorPatchState(
      activeLayout: defaultLayout,
      inheritedRace3dByTeam: <String, Race3dJerseyPatchDescriptor>{
        defaultLayout.teamId: descriptor,
      },
    );
  }

  Race3dJerseyPatchDescriptor? resolveForTeam(String teamId) {
    return inheritedRace3dByTeam[teamId];
  }
}

class CustomJerseySponsorPatchNotifier extends StateNotifier<CustomJerseySponsorPatchState> {
  CustomJerseySponsorPatchNotifier() : super(CustomJerseySponsorPatchState.initial());

  void updateLayout(JerseySponsorPatchLayout layout) {
    final descriptor = CustomJerseySponsorPatchPlacer.buildRace3dInheritance(layout);
    final nextMap = Map<String, Race3dJerseyPatchDescriptor>.from(state.inheritedRace3dByTeam);
    nextMap[layout.teamId] = descriptor;
    state = CustomJerseySponsorPatchState(
      activeLayout: layout,
      inheritedRace3dByTeam: Map<String, Race3dJerseyPatchDescriptor>.unmodifiable(nextMap),
    );
  }

  void updatePatch(JerseySponsorPatchSpec spec) {
    updateLayout(state.activeLayout.withUpdatedPatch(spec));
  }

  void syncTeamMetadata({
    required String teamId,
    required String primarySponsor,
    required String secondarySponsor,
    required String bikeBrand,
    required String countryIso,
  }) {
    final current = state.activeLayout;
    if (current.teamId != teamId) {
      updateLayout(
        JerseySponsorPatchLayout.defaultForTeam(
          teamId: teamId,
          primarySponsor: primarySponsor,
          secondarySponsor: secondarySponsor,
          bikeBrand: bikeBrand,
          countryIso: countryIso,
        ),
      );
      return;
    }

    var next = current
        .withUpdatedPatch(current.patchFor(SponsorPatchZone.chestMain).copyWith(label: primarySponsor))
        .withUpdatedPatch(current.patchFor(SponsorPatchZone.backMain).copyWith(label: primarySponsor))
        .withUpdatedPatch(current.patchFor(SponsorPatchZone.leftSleeve).copyWith(label: secondarySponsor))
        .withUpdatedPatch(current.patchFor(SponsorPatchZone.rightSleeve).copyWith(label: secondarySponsor))
        .withUpdatedPatch(current.patchFor(SponsorPatchZone.leftBibSide).copyWith(label: secondarySponsor))
        .withUpdatedPatch(current.patchFor(SponsorPatchZone.rightBibSide).copyWith(label: secondarySponsor))
        .withUpdatedPatch(current.patchFor(SponsorPatchZone.collarLeft).copyWith(label: bikeBrand))
        .withUpdatedPatch(
          current.patchFor(SponsorPatchZone.collarRight).copyWith(
                label: countryIso.toUpperCase(),
                countryIso: countryIso.toUpperCase(),
              ),
        );
    updateLayout(next);
  }
}

final customJerseySponsorPatchProvider =
    StateNotifierProvider<CustomJerseySponsorPatchNotifier, CustomJerseySponsorPatchState>(
  (ref) => CustomJerseySponsorPatchNotifier(),
);

/// Precyzyjny `CustomPainter` rysujący koszulkę i spodenki wraz z wszystkimi 8 strefami logotypów.
class CustomJerseySponsorPatchCanvasPainter extends CustomPainter {
  final JerseySponsorPatchLayout layout;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color bibColor;
  final bool isBackView;
  final SponsorPatchZone? selectedZone;
  final SponsorPatchZone? hoveredZone;

  const CustomJerseySponsorPatchCanvasPainter({
    required this.layout,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.bibColor,
    required this.isBackView,
    this.selectedZone,
    this.hoveredZone,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final w = size.width;
    final h = size.height;

    _paintGuideGrid(canvas, w, h);
    _paintBibShorts(canvas, w, h);
    _paintJerseyBody(canvas, w, h);

    for (final zone in SponsorPatchZone.values) {
      if (!zone.isVisibleInView(isBackView: isBackView)) continue;
      final spec = layout.patchFor(zone);
      if (!spec.isVisible) continue;
      _paintPatch(canvas, size, spec);
    }

    // Pierścień wyboru / podświetlenia aktywnej strefy
    for (final zone in SponsorPatchZone.values) {
      if (!zone.isVisibleInView(isBackView: isBackView)) continue;
      if (zone != selectedZone && zone != hoveredZone) continue;
      final spec = layout.patchFor(zone);
      final center = CustomJerseySponsorPatchPlacer.resolveZoneCanvasCenter(spec, size);
      final radius = CustomJerseySponsorPatchPlacer._hitRadiusForZone(zone, size) * spec.scale;
      final isSelected = zone == selectedZone;
      final ringPaint = Paint()
        ..color = isSelected ? AppColors.goldAccent : AppColors.accentBlue.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.4;
      canvas.drawCircle(center, radius, ringPaint);
    }
  }

  void _paintGuideGrid(Canvas canvas, double w, double h) {
    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.35)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(w * 0.5, h * 0.04), Offset(w * 0.5, h * 0.96), gridPaint);
    canvas.drawLine(Offset(w * 0.08, h * 0.28), Offset(w * 0.92, h * 0.28), gridPaint);
    canvas.drawLine(Offset(w * 0.16, h * 0.72), Offset(w * 0.84, h * 0.72), gridPaint);
  }

  void _paintBibShorts(Canvas canvas, double w, double h) {
    final bibPath = Path()
      ..moveTo(w * 0.29, h * 0.52)
      ..lineTo(w * 0.71, h * 0.52)
      ..lineTo(w * 0.76, h * 0.89)
      ..lineTo(w * 0.55, h * 0.89)
      ..lineTo(w * 0.50, h * 0.66)
      ..lineTo(w * 0.45, h * 0.89)
      ..lineTo(w * 0.24, h * 0.89)
      ..close();

    final bibPaint = Paint()
      ..color = bibColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(bibPath, bibPaint);

    final gripperPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(w * 0.24, h * 0.86, w * 0.21, h * 0.03), gripperPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.55, h * 0.86, w * 0.21, h * 0.03), gripperPaint);

    final outline = Paint()
      ..color = Colors.black38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(bibPath, outline);
  }

  void _paintJerseyBody(Canvas canvas, double w, double h) {
    final jerseyPath = Path()
      ..moveTo(w * 0.37, h * 0.08)
      ..quadraticBezierTo(w * 0.50, isBackView ? h * 0.10 : h * 0.15, w * 0.63, h * 0.08)
      ..lineTo(w * 0.82, h * 0.16)
      ..lineTo(w * 0.94, h * 0.30)
      ..lineTo(w * 0.83, h * 0.35)
      ..lineTo(w * 0.74, h * 0.28)
      ..lineTo(w * 0.72, h * 0.54)
      ..quadraticBezierTo(w * 0.50, h * 0.56, w * 0.28, h * 0.54)
      ..lineTo(w * 0.26, h * 0.28)
      ..lineTo(w * 0.17, h * 0.35)
      ..lineTo(w * 0.06, h * 0.30)
      ..lineTo(w * 0.18, h * 0.16)
      ..close();

    final basePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(jerseyPath, basePaint);

    // Pas piersiowy dla kontrastu z herbem sponsora
    canvas.save();
    canvas.clipPath(jerseyPath);
    final bandPaint = Paint()
      ..color = secondaryColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, h * 0.22, w, h * 0.13), bandPaint);

    // Stójka kołnierzyka
    final collarPaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.032;
    final collarPath = Path()
      ..moveTo(w * 0.36, h * 0.08)
      ..quadraticBezierTo(w * 0.50, isBackView ? h * 0.11 : h * 0.16, w * 0.64, h * 0.08);
    canvas.drawPath(collarPath, collarPaint);
    canvas.restore();

    if (isBackView) {
      final pocketPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(w * 0.31, h * 0.41, w * 0.38, h * 0.11), pocketPaint);
    } else {
      final zipPaint = Paint()
        ..color = Colors.black45
        ..strokeWidth = 1.6;
      canvas.drawLine(Offset(w * 0.50, h * 0.15), Offset(w * 0.50, h * 0.54), zipPaint);
    }

    final outline = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(jerseyPath, outline);
  }

  void _paintPatch(Canvas canvas, Size size, JerseySponsorPatchSpec spec) {
    final center = CustomJerseySponsorPatchPlacer.resolveZoneCanvasCenter(spec, size);
    final minDim = math.min(size.width, size.height);
    final bgColor = CustomJerseySponsorPatchPlacer.parseHexColor(spec.backgroundColorHex);
    final fgColor = CustomJerseySponsorPatchPlacer.parseHexColor(
      spec.foregroundColorHex,
      fallback: Colors.white,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(spec.rotationDeg * math.pi / 180.0);
    canvas.scale(spec.scale);

    if (spec.zone == SponsorPatchZone.collarRight) {
      _paintCollarFlag(canvas, minDim, spec.countryIso);
      canvas.restore();
      return;
    }

    if (spec.zone == SponsorPatchZone.collarLeft) {
      _paintCollarBikeBadge(canvas, minDim, spec.label, bgColor, fgColor);
      canvas.restore();
      return;
    }

    final double badgeW;
    final double badgeH;
    if (spec.zone == SponsorPatchZone.chestMain || spec.zone == SponsorPatchZone.backMain) {
      badgeW = minDim * 0.22;
      badgeH = minDim * 0.13;
    } else if (spec.zone.isBib) {
      badgeW = minDim * 0.125;
      badgeH = minDim * 0.068;
    } else {
      badgeW = minDim * 0.115;
      badgeH = minDim * 0.056;
    }

    final crestPath = _buildCrestPath(spec.crestShape, badgeW, badgeH);
    final fillPaint = Paint()
      ..color = bgColor.withValues(alpha: 0.94)
      ..style = PaintingStyle.fill;
    canvas.drawPath(crestPath, fillPaint);

    final borderPaint = Paint()
      ..color = fgColor.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(crestPath, borderPaint);

    final fontSize = (badgeH * 0.36).clamp(6.5, 13.0);
    final tp = TextPainter(
      text: TextSpan(
        text: spec.label.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          color: fgColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: badgeW * 0.88);
    tp.paint(canvas, Offset(-tp.width * 0.5, -tp.height * 0.5));

    canvas.restore();
  }

  void _paintCollarFlag(Canvas canvas, double minDim, String countryIso) {
    final flag = NationalFlagPalette.resolve(countryIso);
    final fw = minDim * 0.075;
    final fh = minDim * 0.046;
    final rect = Rect.fromCenter(center: Offset.zero, width: fw, height: fh);

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));
    final count = flag.stripeColors.length;
    for (int i = 0; i < count; i++) {
      final p = Paint()..color = flag.stripeColors[i];
      if (flag.isVertical) {
        final sw = fw / count;
        canvas.drawRect(Rect.fromLTWH(rect.left + i * sw, rect.top, sw + 0.5, fh), p);
      } else {
        final sh = fh / count;
        canvas.drawRect(Rect.fromLTWH(rect.left, rect.top + i * sh, fw, sh + 0.5), p);
      }
    }
    canvas.restore();

    final border = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), border);
  }

  void _paintCollarBikeBadge(
    Canvas canvas,
    double minDim,
    String brand,
    Color bg,
    Color fg,
  ) {
    final bw = minDim * 0.095;
    final bh = minDim * 0.044;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: bw, height: bh),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, Paint()..color = bg);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = fg.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: brand.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Inter',
          color: fg,
          fontSize: (bh * 0.45).clamp(5.5, 9.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: bw * 0.86);
    tp.paint(canvas, Offset(-tp.width * 0.5, -tp.height * 0.5));
  }

  Path _buildCrestPath(SponsorCrestShape shape, double w, double h) {
    final hw = w * 0.5;
    final hh = h * 0.5;
    switch (shape) {
      case SponsorCrestShape.shield:
        return Path()
          ..moveTo(-hw * 0.9, -hh)
          ..lineTo(hw * 0.9, -hh)
          ..lineTo(hw * 0.9, hh * 0.15)
          ..quadraticBezierTo(0, hh * 1.15, 0, hh * 1.15)
          ..quadraticBezierTo(0, hh * 1.15, -hw * 0.9, hh * 0.15)
          ..close();
      case SponsorCrestShape.hexagon:
        return Path()
          ..moveTo(-hw * 0.65, -hh)
          ..lineTo(hw * 0.65, -hh)
          ..lineTo(hw, 0)
          ..lineTo(hw * 0.65, hh)
          ..lineTo(-hw * 0.65, hh)
          ..lineTo(-hw, 0)
          ..close();
      case SponsorCrestShape.circle:
        return Path()..addOval(Rect.fromCenter(center: Offset.zero, width: w * 0.82, height: h * 1.15));
      case SponsorCrestShape.diamond:
        return Path()
          ..moveTo(0, -hh * 1.05)
          ..lineTo(hw, 0)
          ..lineTo(0, hh * 1.05)
          ..lineTo(-hw, 0)
          ..close();
      case SponsorCrestShape.banner:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset.zero, width: w, height: h),
              const Radius.circular(6),
            ),
          );
    }
  }

  @override
  bool shouldRepaint(covariant CustomJerseySponsorPatchCanvasPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.bibColor != bibColor ||
        oldDelegate.isBackView != isBackView ||
        oldDelegate.selectedZone != selectedZone ||
        oldDelegate.hoveredZone != hoveredZone;
  }
}

/// Produkcyjny, w pełni responsywny panel Studia Rozmieszczania Logotypów Sponsorów.
class CustomJerseySponsorPatchPlacerPanel extends ConsumerStatefulWidget {
  final JerseySponsorPatchLayout? initialLayout;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color bibColor;
  final bool enabled;
  final ValueChanged<JerseySponsorPatchLayout>? onLayoutChanged;

  const CustomJerseySponsorPatchPlacerPanel({
    super.key,
    this.initialLayout,
    this.primaryColor = const Color(0xFF002B49),
    this.secondaryColor = const Color(0xFFFFD100),
    this.accentColor = const Color(0xFFD4AF37),
    this.bibColor = const Color(0xFF111317),
    this.enabled = true,
    this.onLayoutChanged,
  });

  @override
  ConsumerState<CustomJerseySponsorPatchPlacerPanel> createState() =>
      _CustomJerseySponsorPatchPlacerPanelState();
}

class _CustomJerseySponsorPatchPlacerPanelState
    extends ConsumerState<CustomJerseySponsorPatchPlacerPanel> {
  late JerseySponsorPatchLayout _layout;
  SponsorPatchZone _selectedZone = SponsorPatchZone.chestMain;
  SponsorPatchZone? _hoveredZone;
  bool _isBackView = false;
  late TextEditingController _labelController;

  static const List<String> _patchSwatches = <String>[
    '#D4AF37',
    '#8E4A49',
    '#181B22',
    '#222630',
    '#38BDF8',
    '#10B981',
    '#FFFFFF',
    '#111317',
  ];

  @override
  void initState() {
    super.initState();
    _layout = widget.initialLayout ?? ref.read(customJerseySponsorPatchProvider).activeLayout;
    _labelController = TextEditingController(text: _layout.patchFor(_selectedZone).label);
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _selectZone(SponsorPatchZone zone) {
    setState(() {
      _selectedZone = zone;
      if (zone.isBackOnly) _isBackView = true;
      if (zone.isFrontOnly) _isBackView = false;
      _labelController.text = _layout.patchFor(zone).label;
    });
  }

  void _updateLayout(JerseySponsorPatchLayout next) {
    if (!widget.enabled) return;
    setState(() {
      _layout = next;
    });
    ref.read(customJerseySponsorPatchProvider.notifier).updateLayout(next);
    widget.onLayoutChanged?.call(next);
  }

  void _updateSelectedPatch(JerseySponsorPatchSpec nextSpec) {
    _updateLayout(_layout.withUpdatedPatch(nextSpec));
  }

  @override
  Widget build(BuildContext context) {
    final validation = CustomJerseySponsorPatchPlacer.validateLayout(_layout);
    final race3dDescriptor = CustomJerseySponsorPatchPlacer.buildRace3dInheritance(_layout);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 880;
        final previewCard = _buildPreviewCard(race3dDescriptor, validation);
        final inspectorCard = _buildInspectorCard(validation);

        if (isWide) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(flex: 5, child: previewCard),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: inspectorCard),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 360, child: previewCard),
              const SizedBox(height: 12),
              inspectorCard,
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewCard(
    Race3dJerseyPatchDescriptor race3d,
    PatchPlacementValidationReport validation,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.layers, color: AppColors.goldAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Podgląd Stref (${validation.activePatchesCount}/8)',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text('Przód', style: TextStyle(fontSize: 11)),
                    selected: !_isBackView,
                    selectedColor: AppColors.goldAccent,
                    onSelected: widget.enabled
                        ? (_) => setState(() => _isBackView = false)
                        : null,
                  ),
                  ChoiceChip(
                    label: const Text('Tył', style: TextStyle(fontSize: 11)),
                    selected: _isBackView,
                    selectedColor: AppColors.goldAccent,
                    onSelected: widget.enabled
                        ? (_) => setState(() => _isBackView = true)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, canvasBox) {
                final side = math.min(canvasBox.maxWidth, canvasBox.maxHeight).clamp(160.0, 420.0);
                final canvasSize = Size(side * 0.78, side);
                return Center(
                  child: MouseRegion(
                    cursor: _hoveredZone != null && widget.enabled
                        ? SystemMouseCursors.grab
                        : SystemMouseCursors.basic,
                    onHover: (event) {
                      if (!widget.enabled) return;
                      final hit = CustomJerseySponsorPatchPlacer.hitTestZone(
                        event.localPosition,
                        canvasSize,
                        _layout,
                        isBackView: _isBackView,
                      );
                      if (hit != _hoveredZone) {
                        setState(() => _hoveredZone = hit);
                      }
                    },
                    onExit: (_) {
                      if (_hoveredZone != null) {
                        setState(() => _hoveredZone = null);
                      }
                    },
                    child: GestureDetector(
                      onTapDown: (details) {
                        if (!widget.enabled) return;
                        final hit = CustomJerseySponsorPatchPlacer.hitTestZone(
                          details.localPosition,
                          canvasSize,
                          _layout,
                          isBackView: _isBackView,
                        );
                        if (hit != null) {
                          _selectZone(hit);
                        }
                      },
                      onPanUpdate: (details) {
                        if (!widget.enabled) return;
                        final currentSpec = _layout.patchFor(_selectedZone);
                        if (!currentSpec.zone.isVisibleInView(isBackView: _isBackView)) return;
                        final moved = CustomJerseySponsorPatchPlacer.applyDragDelta(
                          currentSpec,
                          details.delta,
                          canvasSize,
                        );
                        _updateSelectedPatch(moved);
                      },
                      child: SizedBox(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        child: CustomPaint(
                          painter: CustomJerseySponsorPatchCanvasPainter(
                            layout: _layout,
                            primaryColor: widget.primaryColor,
                            secondaryColor: widget.secondaryColor,
                            accentColor: widget.accentColor,
                            bibColor: widget.bibColor,
                            isBackView: _isBackView,
                            selectedZone: _selectedZone,
                            hoveredZone: _hoveredZone,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: race3d.hasVisiblePatches
                    ? AppColors.statusSuccess.withValues(alpha: 0.55)
                    : AppColors.cardBorder,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.view_in_ar,
                  size: 16,
                  color: race3d.hasVisiblePatches ? AppColors.statusSuccess : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dziedziczenie 3D w wyścigu aktywne • Klatka: ${race3d.chestLabel} • Rower: ${race3d.collarBikeLabel} • Flaga: ${race3d.collarCountryIso}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorCard(PatchPlacementValidationReport validation) {
    final spec = _layout.patchFor(_selectedZone);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
          const Text(
            'Strefy Logotypów i Flagi',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SponsorPatchZone.values.map((zone) {
              final isSelected = zone == _selectedZone;
              final zoneSpec = _layout.patchFor(zone);
              return FilterChip(
                label: Text(
                  zone.shortLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.black : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                showCheckmark: zoneSpec.isVisible && !isSelected,
                selectedColor: AppColors.goldAccent,
                backgroundColor: AppColors.surfaceLight,
                side: BorderSide(
                  color: isSelected ? AppColors.goldAccent : AppColors.cardBorder,
                ),
                onSelected: widget.enabled ? (_) => _selectZone(zone) : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        spec.zone.label,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldAccent,
                        ),
                      ),
                    ),
                    Switch(
                      value: spec.isVisible,
                      activeThumbColor: AppColors.goldAccent,
                      onChanged: widget.enabled
                          ? (val) => _updateSelectedPatch(spec.copyWith(isVisible: val))
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (spec.zone == SponsorPatchZone.collarRight)
                  DropdownButtonFormField<String>(
                    initialValue: NationalFlagPalette.resolve(spec.countryIso).isoCode,
                    decoration: const InputDecoration(
                      labelText: 'Flaga narodowa na kołnierzyku',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: NationalFlagPalette.catalog
                        .map(
                          (f) => DropdownMenuItem<String>(
                            value: f.isoCode,
                            child: Text('${f.countryName} (${f.isoCode})'),
                          ),
                        )
                        .toList(),
                    onChanged: widget.enabled
                        ? (val) {
                            if (val != null) {
                              _updateSelectedPatch(
                                spec.copyWith(countryIso: val, label: val),
                              );
                            }
                          }
                        : null,
                  )
                else
                  TextField(
                    controller: _labelController,
                    enabled: widget.enabled,
                    maxLength: 18,
                    decoration: const InputDecoration(
                      labelText: 'Tekst / Sygnatura Herbu',
                      border: OutlineInputBorder(),
                      isDense: true,
                      counterText: '',
                    ),
                    onChanged: (val) => _updateSelectedPatch(spec.copyWith(label: val)),
                  ),
                if (!spec.zone.isCollar) ...<Widget>[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: SponsorCrestShape.values.map((shape) {
                      final active = spec.crestShape == shape;
                      return ChoiceChip(
                        label: Text(
                          shape.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: active ? Colors.black : AppColors.textPrimary,
                          ),
                        ),
                        selected: active,
                        selectedColor: AppColors.goldAccent,
                        onSelected: widget.enabled
                            ? (sel) {
                                if (sel) _updateSelectedPatch(spec.copyWith(crestShape: shape));
                              }
                            : null,
                      );
                    }).toList(),
                  ),
                ],
                const SizedBox(height: 10),
                _buildSliderRow(
                  label: 'Pozycja X',
                  value: spec.offsetX,
                  min: -0.12,
                  max: 0.12,
                  display: '${(spec.offsetX * 100).toStringAsFixed(1)}%',
                  onChanged: widget.enabled
                      ? (v) => _updateSelectedPatch(spec.copyWith(offsetX: v))
                      : null,
                ),
                _buildSliderRow(
                  label: 'Pozycja Y',
                  value: spec.offsetY,
                  min: -0.12,
                  max: 0.12,
                  display: '${(spec.offsetY * 100).toStringAsFixed(1)}%',
                  onChanged: widget.enabled
                      ? (v) => _updateSelectedPatch(spec.copyWith(offsetY: v))
                      : null,
                ),
                _buildSliderRow(
                  label: 'Skala',
                  value: spec.scale,
                  min: 0.60,
                  max: 1.45,
                  display: '${(spec.scale * 100).round()}%',
                  onChanged: widget.enabled
                      ? (v) => _updateSelectedPatch(spec.copyWith(scale: v))
                      : null,
                ),
                _buildSliderRow(
                  label: 'Obrót',
                  value: spec.rotationDeg,
                  min: -25.0,
                  max: 25.0,
                  display: '${spec.rotationDeg.toStringAsFixed(0)}°',
                  onChanged: widget.enabled
                      ? (v) => _updateSelectedPatch(spec.copyWith(rotationDeg: v))
                      : null,
                ),
                if (spec.zone != SponsorPatchZone.collarRight) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                    'Kolor Tła Herbu:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _patchSwatches.map((hex) {
                      final isCur = spec.backgroundColorHex.toUpperCase() == hex;
                      return InkWell(
                        onTap: widget.enabled
                            ? () => _updateSelectedPatch(spec.copyWith(backgroundColorHex: hex))
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: CustomJerseySponsorPatchPlacer.parseHexColor(hex),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCur ? AppColors.goldAccent : AppColors.cardBorder,
                              width: isCur ? 2.2 : 1.0,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: widget.enabled
                    ? () => _updateLayout(_layout.mirrorSleevesAndBibs())
                    : null,
                icon: const Icon(Icons.flip, size: 16),
                label: const Text('Odbij Rękawki i Spodenki', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton.icon(
                onPressed: widget.enabled
                    ? () {
                        final reset = _layout.resetZone(_selectedZone);
                        _updateLayout(reset);
                        _labelController.text = reset.patchFor(_selectedZone).label;
                      }
                    : null,
                icon: const Icon(Icons.restart_alt, size: 16),
                label: const Text('Resetuj Strefę', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (validation.warnings.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amberWarning.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.amberWarning.withValues(alpha: 0.6)),
              ),
              child: Text(
                validation.warnings.join('\n'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.amberWarning,
                ),
              ),
            ),
          ],
          ],
        ),
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required String display,
    required ValueChanged<double>? onChanged,
  }) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            activeColor: AppColors.goldAccent,
            inactiveColor: AppColors.cardBorder,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
