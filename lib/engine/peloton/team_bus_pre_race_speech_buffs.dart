// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ton przemowy menedżera podczas przedstartowej odprawy w autobusie drużyny.
enum ManagerSpeechTone {
  /// Spokojna analiza taktyczna — obniża tętno spoczynkowe i buduje odporność na stres.
  calmTacticalAnalysis,

  /// Emocjonalna mobilizacja "Wszystko albo nic" — wysokie morale kosztem wyższego tętna i nerwowości.
  emotionalAllInMobilization,

  /// Zdejmowanie presji z młodych — maksymalny komfort i odporność na stres dla kolarzy U23.
  relieveYouthPressure,

  /// Żądanie pełnego poświęcenia dla lidera — silny bodziec dla pomocników i lidera kosztem wolnych strzelców.
  demandFullSacrificeForLeader;

  String get labelPl {
    switch (this) {
      case ManagerSpeechTone.calmTacticalAnalysis:
        return 'Spokojna Analiza Taktyczna';
      case ManagerSpeechTone.emotionalAllInMobilization:
        return 'Emocjonalna Mobilizacja "Wszystko albo nic"';
      case ManagerSpeechTone.relieveYouthPressure:
        return 'Zdejmowanie Presji z Młodych';
      case ManagerSpeechTone.demandFullSacrificeForLeader:
        return 'Żądanie Pełnego Poświęcenia dla Lidera';
    }
  }

  String get shortLabelPl {
    switch (this) {
      case ManagerSpeechTone.calmTacticalAnalysis:
        return 'Analiza Taktyczna';
      case ManagerSpeechTone.emotionalAllInMobilization:
        return 'Wszystko albo nic';
      case ManagerSpeechTone.relieveYouthPressure:
        return 'Ochrona Młodych';
      case ManagerSpeechTone.demandFullSacrificeForLeader:
        return 'Poświęcenie dla Lidera';
    }
  }

  String get quotePl {
    switch (this) {
      case ManagerSpeechTone.calmTacticalAnalysis:
        return '„Trzymamy się planu punkt po punkcie. Zero paniki na zwężeniach, oszczędzamy każdy wat przed finałem.”';
      case ManagerSpeechTone.emotionalAllInMobilization:
        return '„Dziś nie ma jutro! Zostawiamy na asfalcie wszystko, co mamy — jedziemy po zwycięstwo bez kalkulacji!”';
      case ManagerSpeechTone.relieveYouthPressure:
        return '„Młodzi, oddychajcie spokojnie. Nikt nie wymaga od was cudów — jedźcie swoje tempo i uczcie się wyścigu.”';
      case ManagerSpeechTone.demandFullSacrificeForLeader:
        return '„Cała ósemka pracuje dziś na jednego człowieka. Każdy bidon, każdy podmuch wiatru bierzemy na siebie dla lidera.”';
    }
  }

  String get tacticalSummaryPl {
    switch (this) {
      case ManagerSpeechTone.calmTacticalAnalysis:
        return 'Niższe tętno spoczynkowe i wysoka odporność na stres w peletonie';
      case ManagerSpeechTone.emotionalAllInMobilization:
        return 'Ogromny skok morale, lecz wyższe tętno startowe i ryzyko nerwowości';
      case ManagerSpeechTone.relieveYouthPressure:
        return 'Głębokie wyciszenie tętna i duży wzrost morale u kolarzy <= 23 lat';
      case ManagerSpeechTone.demandFullSacrificeForLeader:
        return 'Wzrost determinacji pomocników i morale lidera, lekkie napięcie wolnych ról';
    }
  }

  IconData get icon {
    switch (this) {
      case ManagerSpeechTone.calmTacticalAnalysis:
        return Icons.analytics_outlined;
      case ManagerSpeechTone.emotionalAllInMobilization:
        return Icons.local_fire_department_outlined;
      case ManagerSpeechTone.relieveYouthPressure:
        return Icons.shield_outlined;
      case ManagerSpeechTone.demandFullSacrificeForLeader:
        return Icons.military_tech_outlined;
    }
  }

  Color get accentColor {
    switch (this) {
      case ManagerSpeechTone.calmTacticalAnalysis:
        return AppColors.accentBlue;
      case ManagerSpeechTone.emotionalAllInMobilization:
        return AppColors.crimsonAlert;
      case ManagerSpeechTone.relieveYouthPressure:
        return AppColors.statusSuccess;
      case ManagerSpeechTone.demandFullSacrificeForLeader:
        return AppColors.goldAccent;
    }
  }
}

/// Temat indywidualnej rozmowy menedżera z liderem drużyny przed wyjściem z autobusu.
enum LeaderOneOnOneTopic {
  /// Budowanie pewności siebie i zaufania do własnych nóg.
  trustYourInstincts,

  /// Taktyczne wyciszenie i ochrona przed wiatrem do finałowej rozgrywki.
  stayProtectedUntilFinalClimb,

  /// Świadoma kontrola tętna i nerwów na pierwszych kilometrach.
  manageHeartRateAndNerves,

  /// Mobilizacja lidera jako kapitana inspirującego całą drużynę.
  leadByExampleForTeam;

  String get labelPl {
    switch (this) {
      case LeaderOneOnOneTopic.trustYourInstincts:
        return 'Zaufaj swoim nogom i instynktowi';
      case LeaderOneOnOneTopic.stayProtectedUntilFinalClimb:
        return 'Chroń się w kole do finału';
      case LeaderOneOnOneTopic.manageHeartRateAndNerves:
        return 'Kontroluj tętno i nerwy na starcie';
      case LeaderOneOnOneTopic.leadByExampleForTeam:
        return 'Pokaż drużynie charakter lidera';
    }
  }

  String get promptPl {
    switch (this) {
      case LeaderOneOnOneTopic.trustYourInstincts:
        return '„Masz za sobą świetny blok treningowy. Jeśli poczujesz moment słabości rywali — atakuj bez wahania.”';
      case LeaderOneOnOneTopic.stayProtectedUntilFinalClimb:
        return '„Nie trać ani grama energii w pierwszych dwóch godzinach. Chłopaki dowiozą cię pod finałowy sektor.”';
      case LeaderOneOnOneTopic.manageHeartRateAndNerves:
        return '„Pierwsze 30 km będzie nerwowe. Trzymaj tętno nisko, oddychaj przeponą i nie reaguj na szarpnięcia.”';
      case LeaderOneOnOneTopic.leadByExampleForTeam:
        return '„Drużyna patrzy na ciebie. Jedno pewne słowo na linii startu sprawi, że pójdą za tobą w ogień.”';
    }
  }

  String get leaderReplyPl {
    switch (this) {
      case LeaderOneOnOneTopic.trustYourInstincts:
        return '„Czuję moc w nogach, trenerze. Jeśli otworzy się okno, nie zawaham się.”';
      case LeaderOneOnOneTopic.stayProtectedUntilFinalClimb:
        return '„Zrozumiano. Zostaję schowany za kołami i czekam na decydujący moment.”';
      case LeaderOneOnOneTopic.manageHeartRateAndNerves:
        return '„Spokojnie, puls jest pod kontrolą. Zachowam chłodną głowę w ścisku.”';
      case LeaderOneOnOneTopic.leadByExampleForTeam:
        return '„Biorę to na siebie. Dziś wszyscy damy z siebie maksimum na szosie.”';
    }
  }

  String get effectSummaryPl {
    switch (this) {
      case LeaderOneOnOneTopic.trustYourInstincts:
        return 'Lider: +4.0 morale, +6% odporności na stres';
      case LeaderOneOnOneTopic.stayProtectedUntilFinalClimb:
        return 'Lider: -1 BPM, +9% odporności na stres, +3.0 morale';
      case LeaderOneOnOneTopic.manageHeartRateAndNerves:
        return 'Lider: -3 BPM, +11% odporności na stres, +2.0 morale';
      case LeaderOneOnOneTopic.leadByExampleForTeam:
        return 'Lider: +7.0 morale (+1 BPM); Pomocnicy: +2.0 morale';
    }
  }

  IconData get icon {
    switch (this) {
      case LeaderOneOnOneTopic.trustYourInstincts:
        return Icons.bolt_outlined;
      case LeaderOneOnOneTopic.stayProtectedUntilFinalClimb:
        return Icons.air_outlined;
      case LeaderOneOnOneTopic.manageHeartRateAndNerves:
        return Icons.favorite_border;
      case LeaderOneOnOneTopic.leadByExampleForTeam:
        return Icons.groups_outlined;
    }
  }
}

/// Rola kolarza w składzie drużyny na dany etap.
enum BusRiderRole {
  leader,
  youngTalent,
  domestique,
  freeRole;

  String get labelPl {
    switch (this) {
      case BusRiderRole.leader:
        return 'Lider';
      case BusRiderRole.youngTalent:
        return 'Młody talent';
      case BusRiderRole.domestique:
        return 'Pomocnik';
      case BusRiderRole.freeRole:
        return 'Wolny strzelec';
    }
  }
}

/// Profil kolarza obecnego na odprawie w autobusie drużyny.
class PreRaceBusRiderProfile {
  final String riderId;
  final String name;
  final int age;
  final BusRiderRole role;
  final int baselineRestingHrBpm;
  final double baselineStressResilience;
  final double baselineMorale;

  const PreRaceBusRiderProfile({
    required this.riderId,
    required this.name,
    required this.age,
    required this.role,
    this.baselineRestingHrBpm = 44,
    this.baselineStressResilience = 0.65,
    this.baselineMorale = 70.0,
  });

  bool get isLeader => role == BusRiderRole.leader;

  bool get isYoungRider => role == BusRiderRole.youngTalent || age <= 23;

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'name': name,
        'age': age,
        'role': role.name,
        'baselineRestingHrBpm': baselineRestingHrBpm,
        'baselineStressResilience': baselineStressResilience,
        'baselineMorale': baselineMorale,
      };

  factory PreRaceBusRiderProfile.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String? ?? BusRiderRole.domestique.name;
    final parsedRole = BusRiderRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => BusRiderRole.domestique,
    );
    return PreRaceBusRiderProfile(
      riderId: json['riderId'] as String? ?? 'rider',
      name: json['name'] as String? ?? 'Kolarz',
      age: (json['age'] as num?)?.toInt() ?? 26,
      role: parsedRole,
      baselineRestingHrBpm: (json['baselineRestingHrBpm'] as num?)?.toInt() ?? 44,
      baselineStressResilience:
          (json['baselineStressResilience'] as num?)?.toDouble() ?? 0.65,
      baselineMorale: (json['baselineMorale'] as num?)?.toDouble() ?? 70.0,
    );
  }
}

/// Wyliczone modyfikatory przedstartowe dla pojedynczego kolarza po odprawie w autobusie.
class RiderPreRaceSpeechBuff {
  final String riderId;
  final String riderName;
  final BusRiderRole role;
  final int baselineRestingHrBpm;
  final int restingHeartRateDeltaBpm;
  final int effectiveRestingHrBpm;
  final double baselineStressResilience;
  final double pelotonStressResilienceDelta;
  final double effectiveStressResilience;
  final double baselineMorale;
  final double initialMoraleDelta;
  final double effectiveInitialMorale;
  final String reactionQuotePl;

  const RiderPreRaceSpeechBuff({
    required this.riderId,
    required this.riderName,
    required this.role,
    required this.baselineRestingHrBpm,
    required this.restingHeartRateDeltaBpm,
    required this.effectiveRestingHrBpm,
    required this.baselineStressResilience,
    required this.pelotonStressResilienceDelta,
    required this.effectiveStressResilience,
    required this.baselineMorale,
    required this.initialMoraleDelta,
    required this.effectiveInitialMorale,
    required this.reactionQuotePl,
  });

  Map<String, dynamic> toJson() => {
        'riderId': riderId,
        'riderName': riderName,
        'role': role.name,
        'baselineRestingHrBpm': baselineRestingHrBpm,
        'restingHeartRateDeltaBpm': restingHeartRateDeltaBpm,
        'effectiveRestingHrBpm': effectiveRestingHrBpm,
        'baselineStressResilience': baselineStressResilience,
        'pelotonStressResilienceDelta': pelotonStressResilienceDelta,
        'effectiveStressResilience': effectiveStressResilience,
        'baselineMorale': baselineMorale,
        'initialMoraleDelta': initialMoraleDelta,
        'effectiveInitialMorale': effectiveInitialMorale,
        'reactionQuotePl': reactionQuotePl,
      };

  factory RiderPreRaceSpeechBuff.fromJson(Map<String, dynamic> json) {
    final roleName = json['role'] as String? ?? BusRiderRole.domestique.name;
    final parsedRole = BusRiderRole.values.firstWhere(
      (r) => r.name == roleName,
      orElse: () => BusRiderRole.domestique,
    );
    return RiderPreRaceSpeechBuff(
      riderId: json['riderId'] as String? ?? 'rider',
      riderName: json['riderName'] as String? ?? 'Kolarz',
      role: parsedRole,
      baselineRestingHrBpm: (json['baselineRestingHrBpm'] as num?)?.toInt() ?? 44,
      restingHeartRateDeltaBpm:
          (json['restingHeartRateDeltaBpm'] as num?)?.toInt() ?? 0,
      effectiveRestingHrBpm:
          (json['effectiveRestingHrBpm'] as num?)?.toInt() ?? 44,
      baselineStressResilience:
          (json['baselineStressResilience'] as num?)?.toDouble() ?? 0.65,
      pelotonStressResilienceDelta:
          (json['pelotonStressResilienceDelta'] as num?)?.toDouble() ?? 0.0,
      effectiveStressResilience:
          (json['effectiveStressResilience'] as num?)?.toDouble() ?? 0.65,
      baselineMorale: (json['baselineMorale'] as num?)?.toDouble() ?? 70.0,
      initialMoraleDelta:
          (json['initialMoraleDelta'] as num?)?.toDouble() ?? 0.0,
      effectiveInitialMorale:
          (json['effectiveInitialMorale'] as num?)?.toDouble() ?? 70.0,
      reactionQuotePl: json['reactionQuotePl'] as String? ?? '',
    );
  }
}

/// Zbiorczy raport modyfikatorów z odprawy przedstartowej w autobusie drużyny.
class TeamBusSpeechBuffSummary {
  final ManagerSpeechTone selectedTone;
  final LeaderOneOnOneTopic? leaderTopic;
  final String? leaderName;
  final double avgRestingHrDeltaBpm;
  final double avgStressResilienceDelta;
  final double avgInitialMoraleDelta;
  final int leaderRestingHrDeltaBpm;
  final double leaderStressResilienceDelta;
  final double leaderMoraleDelta;
  final List<RiderPreRaceSpeechBuff> riderBuffs;
  final String speechTranscriptPl;
  final bool isBriefingLocked;

  const TeamBusSpeechBuffSummary({
    required this.selectedTone,
    required this.leaderTopic,
    required this.leaderName,
    required this.avgRestingHrDeltaBpm,
    required this.avgStressResilienceDelta,
    required this.avgInitialMoraleDelta,
    required this.leaderRestingHrDeltaBpm,
    required this.leaderStressResilienceDelta,
    required this.leaderMoraleDelta,
    required this.riderBuffs,
    required this.speechTranscriptPl,
    this.isBriefingLocked = false,
  });

  TeamBusSpeechBuffSummary copyWith({
    ManagerSpeechTone? selectedTone,
    LeaderOneOnOneTopic? leaderTopic,
    bool clearLeaderTopic = false,
    String? leaderName,
    double? avgRestingHrDeltaBpm,
    double? avgStressResilienceDelta,
    double? avgInitialMoraleDelta,
    int? leaderRestingHrDeltaBpm,
    double? leaderStressResilienceDelta,
    double? leaderMoraleDelta,
    List<RiderPreRaceSpeechBuff>? riderBuffs,
    String? speechTranscriptPl,
    bool? isBriefingLocked,
  }) {
    return TeamBusSpeechBuffSummary(
      selectedTone: selectedTone ?? this.selectedTone,
      leaderTopic:
          clearLeaderTopic ? null : (leaderTopic ?? this.leaderTopic),
      leaderName: leaderName ?? this.leaderName,
      avgRestingHrDeltaBpm: avgRestingHrDeltaBpm ?? this.avgRestingHrDeltaBpm,
      avgStressResilienceDelta:
          avgStressResilienceDelta ?? this.avgStressResilienceDelta,
      avgInitialMoraleDelta:
          avgInitialMoraleDelta ?? this.avgInitialMoraleDelta,
      leaderRestingHrDeltaBpm:
          leaderRestingHrDeltaBpm ?? this.leaderRestingHrDeltaBpm,
      leaderStressResilienceDelta:
          leaderStressResilienceDelta ?? this.leaderStressResilienceDelta,
      leaderMoraleDelta: leaderMoraleDelta ?? this.leaderMoraleDelta,
      riderBuffs: riderBuffs ?? this.riderBuffs,
      speechTranscriptPl: speechTranscriptPl ?? this.speechTranscriptPl,
      isBriefingLocked: isBriefingLocked ?? this.isBriefingLocked,
    );
  }

  Map<String, dynamic> toJson() => {
        'selectedTone': selectedTone.name,
        'leaderTopic': leaderTopic?.name,
        'leaderName': leaderName,
        'avgRestingHrDeltaBpm': avgRestingHrDeltaBpm,
        'avgStressResilienceDelta': avgStressResilienceDelta,
        'avgInitialMoraleDelta': avgInitialMoraleDelta,
        'leaderRestingHrDeltaBpm': leaderRestingHrDeltaBpm,
        'leaderStressResilienceDelta': leaderStressResilienceDelta,
        'leaderMoraleDelta': leaderMoraleDelta,
        'riderBuffs': riderBuffs.map((e) => e.toJson()).toList(),
        'speechTranscriptPl': speechTranscriptPl,
        'isBriefingLocked': isBriefingLocked,
      };
}

/// Silnik przedstartowej odprawy motywacyjnej w autobusie drużyny.
///
/// Przelicza wybór tonu przemowy menedżera oraz indywidualnej rozmowy z liderem
/// na konkretne modyfikatory tętna spoczynkowego [BPM], odporności na stres w peletonie
/// oraz początkowego morale przed wyjściem na linię startu.
class TeamBusPreRaceSpeechBuffs {
  TeamBusPreRaceSpeechBuffs._();

  static const int minEffectiveRestingHrBpm = 32;
  static const int maxEffectiveRestingHrBpm = 70;
  static const double minStressResilience = 0.05;
  static const double maxStressResilience = 1.0;
  static const double minMorale = 0.0;
  static const double maxMorale = 100.0;

  /// Domyślny przykładowy skład drużyny na odprawę (używany m.in. w podglądzie).
  static const List<PreRaceBusRiderProfile> defaultDemoSquad = [
    PreRaceBusRiderProfile(
      riderId: 'r1',
      name: 'M. Kowalski',
      age: 28,
      role: BusRiderRole.leader,
      baselineRestingHrBpm: 40,
      baselineStressResilience: 0.76,
      baselineMorale: 76.0,
    ),
    PreRaceBusRiderProfile(
      riderId: 'r2',
      name: 'J. Nowak',
      age: 21,
      role: BusRiderRole.youngTalent,
      baselineRestingHrBpm: 46,
      baselineStressResilience: 0.54,
      baselineMorale: 68.0,
    ),
    PreRaceBusRiderProfile(
      riderId: 'r3',
      name: 'T. Wiśniewski',
      age: 30,
      role: BusRiderRole.domestique,
      baselineRestingHrBpm: 43,
      baselineStressResilience: 0.71,
      baselineMorale: 72.0,
    ),
    PreRaceBusRiderProfile(
      riderId: 'r4',
      name: 'P. Zieliński',
      age: 26,
      role: BusRiderRole.domestique,
      baselineRestingHrBpm: 44,
      baselineStressResilience: 0.67,
      baselineMorale: 70.0,
    ),
    PreRaceBusRiderProfile(
      riderId: 'r5',
      name: 'K. Majewski',
      age: 25,
      role: BusRiderRole.freeRole,
      baselineRestingHrBpm: 45,
      baselineStressResilience: 0.62,
      baselineMorale: 69.0,
    ),
  ];

  /// Wylicza pełny zestaw modyfikatorów dla całej drużyny po odprawie w autobusie.
  static TeamBusSpeechBuffSummary evaluateBriefing({
    required ManagerSpeechTone tone,
    LeaderOneOnOneTopic? leaderTopic,
    required List<PreRaceBusRiderProfile> squad,
    bool isBriefingLocked = false,
  }) {
    if (squad.isEmpty) {
      return TeamBusSpeechBuffSummary(
        selectedTone: tone,
        leaderTopic: leaderTopic,
        leaderName: null,
        avgRestingHrDeltaBpm: 0.0,
        avgStressResilienceDelta: 0.0,
        avgInitialMoraleDelta: 0.0,
        leaderRestingHrDeltaBpm: 0,
        leaderStressResilienceDelta: 0.0,
        leaderMoraleDelta: 0.0,
        riderBuffs: const [],
        speechTranscriptPl: tone.quotePl,
        isBriefingLocked: isBriefingLocked,
      );
    }

    final buffs = squad
        .map(
          (rider) => evaluateRiderBuff(
            rider: rider,
            tone: tone,
            leaderTopic: leaderTopic,
          ),
        )
        .toList(growable: false);

    final double count = buffs.length.toDouble();
    final double sumHr = buffs.fold<double>(
      0.0,
      (acc, b) => acc + b.restingHeartRateDeltaBpm,
    );
    final double sumStress = buffs.fold<double>(
      0.0,
      (acc, b) => acc + b.pelotonStressResilienceDelta,
    );
    final double sumMorale = buffs.fold<double>(
      0.0,
      (acc, b) => acc + b.initialMoraleDelta,
    );

    final RiderPreRaceSpeechBuff? leaderBuff = buffs
        .cast<RiderPreRaceSpeechBuff?>()
        .firstWhere((b) => b?.role == BusRiderRole.leader, orElse: () => null);

    final StringBuffer transcript = StringBuffer()..writeln(tone.quotePl);
    if (leaderTopic != null && leaderBuff != null) {
      transcript
        ..writeln()
        ..writeln('Rozmowa z liderem (${leaderBuff.riderName}):')
        ..writeln(leaderTopic.promptPl)
        ..writeln(leaderTopic.leaderReplyPl);
    }

    return TeamBusSpeechBuffSummary(
      selectedTone: tone,
      leaderTopic: leaderTopic,
      leaderName: leaderBuff?.riderName,
      avgRestingHrDeltaBpm: sumHr / count,
      avgStressResilienceDelta: sumStress / count,
      avgInitialMoraleDelta: sumMorale / count,
      leaderRestingHrDeltaBpm: leaderBuff?.restingHeartRateDeltaBpm ?? 0,
      leaderStressResilienceDelta:
          leaderBuff?.pelotonStressResilienceDelta ?? 0.0,
      leaderMoraleDelta: leaderBuff?.initialMoraleDelta ?? 0.0,
      riderBuffs: buffs,
      speechTranscriptPl: transcript.toString().trim(),
      isBriefingLocked: isBriefingLocked,
    );
  }

  /// Wylicza modyfikatory przedstartowe dla pojedynczego kolarza.
  static RiderPreRaceSpeechBuff evaluateRiderBuff({
    required PreRaceBusRiderProfile rider,
    required ManagerSpeechTone tone,
    LeaderOneOnOneTopic? leaderTopic,
  }) {
    int hrDelta = 0;
    double stressDelta = 0.0;
    double moraleDelta = 0.0;
    String reactionQuote = '';

    switch (tone) {
      case ManagerSpeechTone.calmTacticalAnalysis:
        hrDelta = rider.isLeader ? -4 : -3;
        stressDelta = rider.isLeader ? 0.16 : 0.14;
        moraleDelta = 6.0;
        reactionQuote = '„Plan jest jasny. Pełny spokój i koncentracja.”';
        break;

      case ManagerSpeechTone.emotionalAllInMobilization:
        hrDelta = rider.isYoungRider ? 4 : 3;
        stressDelta = rider.isYoungRider ? -0.08 : -0.05;
        moraleDelta = rider.isLeader || rider.role == BusRiderRole.freeRole
            ? 16.0
            : 13.0;
        reactionQuote = '„Adrenalina aż buzuje — jedziemy na 110%!”';
        break;

      case ManagerSpeechTone.relieveYouthPressure:
        if (rider.isYoungRider) {
          hrDelta = -4;
          stressDelta = 0.18;
          moraleDelta = 15.0;
          reactionQuote = '„Uff, spadł ze mnie ogromny ciężar. Dam radę!”';
        } else {
          hrDelta = -1;
          stressDelta = 0.06;
          moraleDelta = 4.0;
          reactionQuote = '„Dobre podejście, młodzi nie spalą się na starcie.”';
        }
        break;

      case ManagerSpeechTone.demandFullSacrificeForLeader:
        switch (rider.role) {
          case BusRiderRole.leader:
            hrDelta = 1;
            stressDelta = 0.10;
            moraleDelta = 12.0;
            reactionQuote = '„Doceniam wsparcie chłopaków. Nie zawiodę ich.”';
            break;
          case BusRiderRole.domestique:
            hrDelta = 1;
            stressDelta = 0.15;
            moraleDelta = 10.0;
            reactionQuote = '„Zadanie czytelne: chronimy lidera za wszelką cenę.”';
            break;
          case BusRiderRole.youngTalent:
            hrDelta = 2;
            stressDelta = 0.04;
            moraleDelta = 2.0;
            reactionQuote = '„Zrobię swoje na wietrze, ile starczy sił.”';
            break;
          case BusRiderRole.freeRole:
            hrDelta = 2;
            stressDelta = 0.02;
            moraleDelta = -2.0;
            reactionQuote = '„Szkoda wolnej ręki, ale dobro ekipy najważniejsze.”';
            break;
        }
        break;
    }

    // Modyfikatory indywidualnej rozmowy z liderem
    if (leaderTopic != null) {
      if (rider.isLeader) {
        switch (leaderTopic) {
          case LeaderOneOnOneTopic.trustYourInstincts:
            stressDelta += 0.06;
            moraleDelta += 4.0;
            reactionQuote = leaderTopic.leaderReplyPl;
            break;
          case LeaderOneOnOneTopic.stayProtectedUntilFinalClimb:
            hrDelta -= 1;
            stressDelta += 0.09;
            moraleDelta += 3.0;
            reactionQuote = leaderTopic.leaderReplyPl;
            break;
          case LeaderOneOnOneTopic.manageHeartRateAndNerves:
            hrDelta -= 3;
            stressDelta += 0.11;
            moraleDelta += 2.0;
            reactionQuote = leaderTopic.leaderReplyPl;
            break;
          case LeaderOneOnOneTopic.leadByExampleForTeam:
            hrDelta += 1;
            stressDelta += 0.04;
            moraleDelta += 7.0;
            reactionQuote = leaderTopic.leaderReplyPl;
            break;
        }
      } else if (leaderTopic == LeaderOneOnOneTopic.leadByExampleForTeam &&
          rider.role == BusRiderRole.domestique) {
        // Efekt kapitańskiej postawy lidera przenosi się na pomocników.
        moraleDelta += 2.0;
      }
    }

    final int effectiveHr = (rider.baselineRestingHrBpm + hrDelta).clamp(
      minEffectiveRestingHrBpm,
      maxEffectiveRestingHrBpm,
    );
    final double effectiveStress =
        (rider.baselineStressResilience + stressDelta).clamp(
      minStressResilience,
      maxStressResilience,
    );
    final double effectiveMorale = (rider.baselineMorale + moraleDelta).clamp(
      minMorale,
      maxMorale,
    );

    return RiderPreRaceSpeechBuff(
      riderId: rider.riderId,
      riderName: rider.name,
      role: rider.role,
      baselineRestingHrBpm: rider.baselineRestingHrBpm,
      restingHeartRateDeltaBpm: effectiveHr - rider.baselineRestingHrBpm,
      effectiveRestingHrBpm: effectiveHr,
      baselineStressResilience: rider.baselineStressResilience,
      pelotonStressResilienceDelta:
          effectiveStress - rider.baselineStressResilience,
      effectiveStressResilience: effectiveStress,
      baselineMorale: rider.baselineMorale,
      initialMoraleDelta: effectiveMorale - rider.baselineMorale,
      effectiveInitialMorale: effectiveMorale,
      reactionQuotePl: reactionQuote,
    );
  }

  /// Sugeruje optymalny ton przemowy na podstawie wieku składu, morale i stawki etapu.
  static ManagerSpeechTone recommendTone({
    required List<PreRaceBusRiderProfile> squad,
    required bool isHighStakesStage,
    required double averageSquadMorale,
  }) {
    if (squad.isEmpty) {
      return ManagerSpeechTone.calmTacticalAnalysis;
    }

    final int youngCount = squad.where((r) => r.isYoungRider).length;
    if (youngCount >= math.max(2, (squad.length / 2).ceil())) {
      return ManagerSpeechTone.relieveYouthPressure;
    }
    if (averageSquadMorale < 60.0) {
      return ManagerSpeechTone.emotionalAllInMobilization;
    }
    if (isHighStakesStage &&
        squad.any((r) => r.role == BusRiderRole.leader)) {
      return ManagerSpeechTone.demandFullSacrificeForLeader;
    }
    return ManagerSpeechTone.calmTacticalAnalysis;
  }
}

/// Produkcyjny, responsywny panel interaktywnej odprawy motywacyjnej w autobusie drużyny.
///
/// Obsługuje pełne stany `hover` / `active` / `disabled` / `focus`, płynne przejścia
/// `250ms` (`Curves.easeOutCubic`), układ `LayoutBuilder` dla `390x844`, `1024x768`
/// oraz `1600x900`, paletę [AppColors] i typografię `Inter`.
class TeamBusPreRaceSpeechPanel extends StatefulWidget {
  final List<PreRaceBusRiderProfile> squad;
  final ManagerSpeechTone initialTone;
  final LeaderOneOnOneTopic? initialLeaderTopic;
  final String stageTitle;
  final bool isHighStakesStage;
  final bool isExternallyLocked;
  final ValueChanged<TeamBusSpeechBuffSummary>? onBriefingConfirmed;
  final ValueChanged<TeamBusSpeechBuffSummary>? onSelectionChanged;

  const TeamBusPreRaceSpeechPanel({
    super.key,
    this.squad = TeamBusPreRaceSpeechBuffs.defaultDemoSquad,
    this.initialTone = ManagerSpeechTone.calmTacticalAnalysis,
    this.initialLeaderTopic = LeaderOneOnOneTopic.stayProtectedUntilFinalClimb,
    this.stageTitle = 'Etap 15 — Finał w Pirenejach',
    this.isHighStakesStage = true,
    this.isExternallyLocked = false,
    this.onBriefingConfirmed,
    this.onSelectionChanged,
  });

  @override
  State<TeamBusPreRaceSpeechPanel> createState() =>
      _TeamBusPreRaceSpeechPanelState();
}

class _TeamBusPreRaceSpeechPanelState extends State<TeamBusPreRaceSpeechPanel> {
  static const TextStyle _interBase = TextStyle(
    fontFamily: 'Inter',
    letterSpacing: -0.2,
  );

  late ManagerSpeechTone _selectedTone;
  LeaderOneOnOneTopic? _selectedLeaderTopic;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _selectedTone = widget.initialTone;
    _selectedLeaderTopic = widget.initialLeaderTopic;
    _isConfirmed = widget.isExternallyLocked;
  }

  @override
  void didUpdateWidget(covariant TeamBusPreRaceSpeechPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExternallyLocked != oldWidget.isExternallyLocked) {
      _isConfirmed = widget.isExternallyLocked;
    }
  }

  bool get _isLocked => _isConfirmed || widget.isExternallyLocked;

  TeamBusSpeechBuffSummary get _currentSummary =>
      TeamBusPreRaceSpeechBuffs.evaluateBriefing(
        tone: _selectedTone,
        leaderTopic: _selectedLeaderTopic,
        squad: widget.squad,
        isBriefingLocked: _isLocked,
      );

  void _selectTone(ManagerSpeechTone tone) {
    if (_isLocked || _selectedTone == tone) return;
    setState(() {
      _selectedTone = tone;
    });
    widget.onSelectionChanged?.call(_currentSummary);
  }

  void _selectLeaderTopic(LeaderOneOnOneTopic? topic) {
    if (_isLocked || _selectedLeaderTopic == topic) return;
    setState(() {
      _selectedLeaderTopic = topic;
    });
    widget.onSelectionChanged?.call(_currentSummary);
  }

  void _confirmBriefing() {
    if (_isLocked) return;
    setState(() {
      _isConfirmed = true;
    });
    widget.onBriefingConfirmed?.call(_currentSummary);
  }

  void _reopenBriefing() {
    if (widget.isExternallyLocked) return;
    setState(() {
      _isConfirmed = false;
    });
    widget.onSelectionChanged?.call(_currentSummary);
  }

  @override
  Widget build(BuildContext context) {
    final TeamBusSpeechBuffSummary summary = _currentSummary;
    final double avgMorale = widget.squad.isEmpty
        ? 70.0
        : widget.squad.fold<double>(0.0, (a, r) => a + r.baselineMorale) /
            widget.squad.length;
    final ManagerSpeechTone recommendedTone =
        TeamBusPreRaceSpeechBuffs.recommendTone(
      squad: widget.squad,
      isHighStakesStage: widget.isHighStakesStage,
      averageSquadMorale: avgMorale,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 1024.0;
        final bool isCompact = width < 720.0;
        final bool isWideDesktop = width >= 1180.0;
        final double horizontalPadding = isCompact ? 12.0 : 20.0;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder, width: 1.0),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(summary, recommendedTone, isCompact),
                const SizedBox(height: 16),
                if (isCompact) ...[
                  _buildToneSelectorSection(recommendedTone, isCompact: true),
                  const SizedBox(height: 16),
                  _buildLeaderOneOnOneSection(summary, isCompact: true),
                  const SizedBox(height: 16),
                  _buildSquadImpactSection(summary, isCompact: true),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: isWideDesktop ? 6 : 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildToneSelectorSection(
                              recommendedTone,
                              isCompact: false,
                            ),
                            const SizedBox(height: 16),
                            _buildLeaderOneOnOneSection(
                              summary,
                              isCompact: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: isWideDesktop ? 5 : 4,
                        child: _buildSquadImpactSection(
                          summary,
                          isCompact: false,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                _buildActionFooter(summary, isCompact),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    TeamBusSpeechBuffSummary summary,
    ManagerSpeechTone recommendedTone,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14.0 : 18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isLocked
              ? AppColors.statusSuccess.withValues(alpha: 0.6)
              : const Color(0xFF2A2F3D),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: const Icon(
                      Icons.directions_bus_filled_outlined,
                      color: AppColors.goldAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Odprawa w autobusie drużyny',
                          style: _interBase.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.stageTitle,
                          style: _interBase.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _isLocked
                      ? AppColors.statusSuccess.withValues(alpha: 0.15)
                      : AppColors.goldAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _isLocked
                        ? AppColors.statusSuccess
                        : AppColors.goldAccent.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  _isLocked ? 'ODPRAWA ZATWIERDZONA' : 'PRZED STARTEM',
                  style: _interBase.copyWith(
                    color: _isLocked
                        ? AppColors.statusSuccess
                        : AppColors.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetricPill(
                label: 'Śr. tętno spocz.',
                value: _formatSignedDouble(summary.avgRestingHrDeltaBpm, 'BPM'),
                color: summary.avgRestingHrDeltaBpm <= 0
                    ? AppColors.statusSuccess
                    : AppColors.amberWarning,
              ),
              _buildMetricPill(
                label: 'Odporność na stres',
                value:
                    '${summary.avgStressResilienceDelta >= 0 ? '+' : ''}${(summary.avgStressResilienceDelta * 100).toStringAsFixed(0)}%',
                color: summary.avgStressResilienceDelta >= 0
                    ? AppColors.accentBlue
                    : AppColors.crimsonAlert,
              ),
              _buildMetricPill(
                label: 'Początkowe morale',
                value: _formatSignedDouble(summary.avgInitialMoraleDelta, ''),
                color: summary.avgInitialMoraleDelta >= 0
                    ? AppColors.goldAccent
                    : AppColors.crimsonAlert,
              ),
              _buildMetricPill(
                label: 'Sugestia DS',
                value: recommendedTone.shortLabelPl,
                color: recommendedTone.accentColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3D)),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: _interBase.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: value,
              style: _interBase.copyWith(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneSelectorSection(
    ManagerSpeechTone recommendedTone, {
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '1. Ton przemowy menedżera',
            style: _interBase.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Wybierz przekaz w autobusie tuż przed podpisaniem listy startowej.',
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...ManagerSpeechTone.values.map((tone) {
            final bool isSelected = _selectedTone == tone;
            final bool isRecommended = tone == recommendedTone;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _InteractiveBusCard(
                key: ValueKey('speech_tone_${tone.name}'),
                isSelected: isSelected,
                isDisabled: _isLocked,
                accentColor: tone.accentColor,
                onTap: () => _selectTone(tone),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          tone.icon,
                          size: 18,
                          color: isSelected
                              ? tone.accentColor
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tone.labelPl,
                            style: _interBase.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.goldAccent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.goldAccent
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                            child: Text(
                              'ZALECANE',
                              style: _interBase.copyWith(
                                color: AppColors.goldAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tone.quotePl,
                      style: _interBase.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tone.tacticalSummaryPl,
                      style: _interBase.copyWith(
                        color: tone.accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLeaderOneOnOneSection(
    TeamBusSpeechBuffSummary summary, {
    required bool isCompact,
  }) {
    final String leaderDisplay = summary.leaderName ?? 'Lider zespołu';
    return Container(
      padding: EdgeInsets.all(isCompact ? 14.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '2. Indywidualna rozmowa z liderem ($leaderDisplay)',
                  style: _interBase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (_selectedLeaderTopic != null && !_isLocked)
                TextButton(
                  onPressed: () => _selectLeaderTopic(null),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Pomiń',
                    style: _interBase.copyWith(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Krótka rozmowa w cztery oczy na końcu autobusu przed wyjściem na rampę.',
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...LeaderOneOnOneTopic.values.map((topic) {
            final bool isSelected = _selectedLeaderTopic == topic;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _InteractiveBusCard(
                key: ValueKey('leader_topic_${topic.name}'),
                isSelected: isSelected,
                isDisabled: _isLocked,
                accentColor: AppColors.goldAccent,
                onTap: () => _selectLeaderTopic(topic),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          topic.icon,
                          size: 17,
                          color: isSelected
                              ? AppColors.goldAccent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            topic.labelPl,
                            style: _interBase.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.effectSummaryPl,
                      style: _interBase.copyWith(
                        color: isSelected
                            ? AppColors.goldAccent
                            : AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${topic.promptPl}\n${topic.leaderReplyPl}',
                        style: _interBase.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSquadImpactSection(
    TeamBusSpeechBuffSummary summary, {
    required bool isCompact,
  }) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 14.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '3. Wpływ na skład przed startem',
            style: _interBase.copyWith(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tętno spoczynkowe (BPM), odporność na stres w peletonie oraz początkowe morale.',
            style: _interBase.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          if (summary.riderBuffs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Brak kolarzy przypisanych do autobusu.',
                  style: _interBase.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ...summary.riderBuffs.map((buff) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: buff.role == BusRiderRole.leader
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
                        : const Color(0xFF2A2F3D),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            buff.riderName,
                            style: _interBase.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2A2F3D)),
                          ),
                          child: Text(
                            buff.role.labelPl,
                            style: _interBase.copyWith(
                              color: buff.role == BusRiderRole.leader
                                  ? AppColors.goldAccent
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildRiderStatChip(
                          label: 'Tętno',
                          value:
                              '${buff.effectiveRestingHrBpm} BPM (${buff.restingHeartRateDeltaBpm >= 0 ? '+' : ''}${buff.restingHeartRateDeltaBpm})',
                          color: buff.restingHeartRateDeltaBpm <= 0
                              ? AppColors.statusSuccess
                              : AppColors.amberWarning,
                        ),
                        _buildRiderStatChip(
                          label: 'Stres',
                          value:
                              '${(buff.effectiveStressResilience * 100).toStringAsFixed(0)}% (${buff.pelotonStressResilienceDelta >= 0 ? '+' : ''}${(buff.pelotonStressResilienceDelta * 100).toStringAsFixed(0)}%)',
                          color: buff.pelotonStressResilienceDelta >= 0
                              ? AppColors.accentBlue
                              : AppColors.crimsonAlert,
                        ),
                        _buildRiderStatChip(
                          label: 'Morale',
                          value:
                              '${buff.effectiveInitialMorale.toStringAsFixed(0)} (${buff.initialMoraleDelta >= 0 ? '+' : ''}${buff.initialMoraleDelta.toStringAsFixed(0)})',
                          color: buff.initialMoraleDelta >= 0
                              ? AppColors.goldAccent
                              : AppColors.crimsonAlert,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      buff.reactionQuotePl,
                      style: _interBase.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildRiderStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        '$label: $value',
        style: _interBase.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildActionFooter(
    TeamBusSpeechBuffSummary summary,
    bool isCompact,
  ) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3D), width: 1.0),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isLocked ? Icons.check_circle_outline : Icons.record_voice_over,
                color: _isLocked
                    ? AppColors.statusSuccess
                    : AppColors.goldAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _isLocked
                      ? 'Modyfikatory nałożone: ${summary.selectedTone.shortLabelPl}'
                      : 'Gotowy do wyjścia z autobusu na linię startu',
                  style: _interBase.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (_isLocked && !widget.isExternallyLocked)
                _InteractiveBusButton(
                  key: const ValueKey('reopen_bus_briefing_btn'),
                  label: 'Zmień odprawę',
                  isPrimary: false,
                  isDisabled: false,
                  onPressed: _reopenBriefing,
                ),
              _InteractiveBusButton(
                key: const ValueKey('confirm_bus_briefing_btn'),
                label: _isLocked
                    ? 'Odprawa zatwierdzona'
                    : 'Zatwierdź odprawę i wyjdź na start',
                isPrimary: true,
                isDisabled: _isLocked,
                onPressed: _confirmBriefing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSignedDouble(double value, String unit) {
    final String sign = value > 0 ? '+' : '';
    final String formatted = value.toStringAsFixed(1);
    return unit.isEmpty ? '$sign$formatted' : '$sign$formatted $unit';
  }
}

class _InteractiveBusCard extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final bool isDisabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _InteractiveBusCard({
    super.key,
    required this.child,
    required this.isSelected,
    required this.isDisabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_InteractiveBusCard> createState() => _InteractiveBusCardState();
}

class _InteractiveBusCardState extends State<_InteractiveBusCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = widget.isDisabled
        ? const Color(0xFF2A2F3D).withValues(alpha: 0.5)
        : widget.isSelected
            ? widget.accentColor
            : _isFocused
                ? AppColors.goldAccent
                : _isHovered
                    ? widget.accentColor.withValues(alpha: 0.65)
                    : const Color(0xFF2A2F3D);

    final Color bgColor = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.45)
        : widget.isSelected
            ? widget.accentColor.withValues(alpha: 0.12)
            : _isPressed
                ? AppColors.surfaceLight.withValues(alpha: 0.95)
                : _isHovered
                    ? AppColors.surfaceLight
                    : AppColors.surfaceLight.withValues(alpha: 0.72);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: widget.isSelected || _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: widget.isDisabled && !widget.isSelected ? 0.6 : 1.0,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _InteractiveBusButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final bool isDisabled;
  final VoidCallback onPressed;

  const _InteractiveBusButton({
    super.key,
    required this.label,
    required this.isPrimary,
    required this.isDisabled,
    required this.onPressed,
  });

  @override
  State<_InteractiveBusButton> createState() => _InteractiveBusButtonState();
}

class _InteractiveBusButtonState extends State<_InteractiveBusButton> {
  bool _isHovered = false;
  bool _isFocused = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.isPrimary
        ? AppColors.primaryAccent
        : AppColors.surfaceLight;
    final Color effectiveBg = widget.isDisabled
        ? AppColors.surfaceLight.withValues(alpha: 0.5)
        : _isPressed
            ? baseColor.withValues(alpha: 0.85)
            : _isHovered
                ? baseColor.withValues(alpha: 0.95)
                : baseColor;

    final Color borderColor = widget.isDisabled
        ? const Color(0xFF2A2F3D)
        : _isFocused
            ? AppColors.goldAccent
            : widget.isPrimary
                ? AppColors.goldAccent.withValues(alpha: 0.55)
                : const Color(0xFF2A2F3D);

    return FocusableActionDetector(
      enabled: !widget.isDisabled,
      onShowHoverHighlight: (hovered) => setState(() => _isHovered = hovered),
      onShowFocusHighlight: (focused) => setState(() => _isFocused = focused),
      mouseCursor: widget.isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onPressed,
        onTapDown: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: widget.isDisabled
            ? null
            : (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: effectiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              letterSpacing: -0.2,
              color: widget.isDisabled
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
