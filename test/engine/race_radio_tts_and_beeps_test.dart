// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/audio/race_radio_tts_and_beeps.dart';
import 'package:pro_peloton_manager/engine/events/race_radio_generator.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('RaceRadioAudioSynthesizer - Dźwięk Krótkofalówki i Sygnały Komputera', () {
    late RaceRadioAudioSynthesizer synthesizer;

    setUp(() {
      synthesizer = const RaceRadioAudioSynthesizer(sampleRate: 44100);
    });

    test('generateRadioSquelchBeep tworzy charakterystyczny dźwięk "Krrr-beep!"', () {
      final buffer = synthesizer.generateRadioSquelchBeep(volume: 0.9);

      // Czas trwania: 55ms szumu + 10ms pauzy + 95ms tonu = 160ms = ~7056 ramek
      expect(buffer.frameCount, greaterThan(6500));
      expect(buffer.frameCount, lessThan(7500));
      expect(buffer.durationSeconds, closeTo(0.160, 0.015));

      // Sprawdzenie obecności energii w fazie szumu (początek bufora)
      double squelchEnergy = 0.0;
      for (int i = 0; i < 2000; i++) {
        squelchEnergy += buffer.left[i].abs();
      }
      expect(squelchEnergy, greaterThan(10.0));

      // Sprawdzenie obecności energii w fazie tonu Roger Beep (koniec bufora)
      double rogerBeepEnergy = 0.0;
      final startBeep = buffer.frameCount - 3000;
      for (int i = startBeep; i < buffer.frameCount; i++) {
        rogerBeepEnergy += buffer.left[i].abs();
      }
      expect(rogerBeepEnergy, greaterThan(50.0));

      // Wszystkie próbki mieszczą się w dopuszczalnym zakresie [-1.0, 1.0]
      for (int i = 0; i < buffer.frameCount; i++) {
        expect(buffer.left[i], inInclusiveRange(-1.0, 1.0));
        expect(buffer.right[i], inInclusiveRange(-1.0, 1.0));
      }

      // Weryfikacja możliwości eksportu do poprawnego pliku WAV
      final wavBytes = buffer.toWavBytes();
      expect(wavBytes.length, equals(44 + (buffer.frameCount * 4)));
      expect(String.fromCharCodes(wavBytes.sublist(0, 4)), equals('RIFF'));
    });

    test('generateRadioCloseSquelch generuje krótki trzask rozłączenia PTT ("Krrr-click")', () {
      final buffer = synthesizer.generateRadioCloseSquelch(volume: 0.7);

      // Czas trwania: ~35 ms = ~1543 ramki
      expect(buffer.durationSeconds, closeTo(0.035, 0.005));
      expect(buffer.frameCount, greaterThan(1400));

      double peak = 0.0;
      for (int i = 0; i < buffer.frameCount; i++) {
        peak = math.max(peak, buffer.left[i].abs());
      }
      expect(peak, greaterThan(0.2));
    });

    test('generateClimbProAlertBeep generuje wznoszące trójtonowe arpeggio piezo', () {
      final buffer = synthesizer.generateClimbProAlertBeep(volume: 0.85);

      // Czas trwania: 55ms + 8ms + 55ms + 8ms + 85ms = 211ms = ~9305 ramek
      expect(buffer.durationSeconds, closeTo(0.211, 0.015));
      expect(buffer.frameCount, greaterThan(8800));

      // Sprawdzenie braku przesterowań
      for (int i = 0; i < buffer.frameCount; i++) {
        expect(buffer.left[i], inInclusiveRange(-1.0, 1.0));
      }

      final dataUri = buffer.toDataUri();
      expect(dataUri.startsWith('data:audio/wav;base64,'), isTrue);
    });

    test('generateWPrimeCriticalAlarmBeep generuje podwójne ostry pisk alarmowy W\' < 15%', () {
      final buffer = synthesizer.generateWPrimeCriticalAlarmBeep(volume: 0.95);

      // Czas trwania: 65ms + 40ms przerwy + 65ms = 170ms = ~7497 ramek
      expect(buffer.durationSeconds, closeTo(0.170, 0.015));

      // Sprawdzenie przerwy (ciszy) pomiędzy dwoma piskami w środku bufora
      final midIdx = buffer.frameCount ~/ 2;
      expect(buffer.left[midIdx].abs(), lessThan(0.01));
      expect(buffer.right[midIdx].abs(), lessThan(0.01));

      // Sprawdzenie energii w pierwszym pisku
      double chirp1Energy = 0.0;
      for (int i = 100; i < 2000; i++) {
        chirp1Energy += buffer.left[i].abs();
      }
      expect(chirp1Energy, greaterThan(20.0));
    });

    test('generateKomSummitChime generuje dwutonowy dzwonek akordu C7 -> G7', () {
      final buffer = synthesizer.generateKomSummitChime(volume: 0.85);
      expect(buffer.durationSeconds, closeTo(0.200, 0.02));
      expect(buffer.frameCount, greaterThan(8000));
    });
  });

  group('RadioSpeechFormat - Oczyszczanie Tekstu i Stylistyka Radia Wyścigowego', () {
    test('cleanTextForTts poprawnie rozwija skróty kolarskie i usuwa nawiasy', () {
      const raw = 'ATAK! [Tadej Pogacar] rwie peleton na 142.5 km przed szczytem KOM (HC)! DS wzywa pomocnika.';
      final cleaned = RadioSpeechFormat.cleanTextForTts(raw);

      expect(cleaned.contains('['), isFalse);
      expect(cleaned.contains(']'), isFalse);
      expect(cleaned.contains('kilometrów'), isTrue);
      expect(cleaned.contains('premia górska'), isTrue);
      expect(cleaned.contains('kategoria poza klasyfikacją'), isTrue);
      expect(cleaned.contains('dyrektor sportowy'), isTrue);
    });

    test('formatForTts dodaje odpowiedni prefiks kanału radiowego', () {
      const msg = RaceRadioMessage(
        id: 'msg_1',
        kilometerMark: 45.0,
        elapsedSeconds: 3600.0,
        channel: RadioChannel.radioTour,
        priority: RadioPriority.urgent,
        senderName: 'Radio Tour',
        message: 'Kraksa w peletonie!',
      );

      final ttsRadioTour = RadioSpeechFormat.formatForTts(msg);
      expect(ttsRadioTour.startsWith('Radio Tour.'), isTrue);

      final dsMsg = msg.copyWith(channel: RadioChannel.directeurSportif);
      final ttsDs = RadioSpeechFormat.formatForTts(dsMsg);
      expect(ttsDs.startsWith('Dyrektor sportowy.'), isTrue);
    });
  });

  group('RaceRadioEventDetector - Wykrywanie Komunikatów do Odegrania "Krrr-beep!"', () {
    test('wykrywa atak rywala i faworyta', () {
      const msg = RaceRadioMessage(
        id: '1',
        kilometerMark: 120.0,
        elapsedSeconds: 9000.0,
        channel: RadioChannel.radioTour,
        priority: RadioPriority.tactical,
        senderName: 'Radio Tour',
        message: 'ATAK FAWORYTA: Jonas Vingegaard zaatakował na stromiźnie!',
      );
      expect(RaceRadioEventDetector.shouldTriggerRadioBeep(msg), isTrue);
    });

    test('wykrywa kraksę na trasie', () {
      const msg = RaceRadioMessage(
        id: '2',
        kilometerMark: 45.0,
        elapsedSeconds: 3500.0,
        channel: RadioChannel.radioTour,
        priority: RadioPriority.urgent,
        senderName: 'Radio Tour',
        message: 'CHUTE! Kraksa na 45 km, leży kilku kolarzy.',
      );
      expect(RaceRadioEventDetector.shouldTriggerRadioBeep(msg), isTrue);
    });

    test('wykrywa bramę Flamme Rouge (1 km do mety)', () {
      const msg = RaceRadioMessage(
        id: '3',
        kilometerMark: 180.0,
        elapsedSeconds: 14000.0,
        channel: RadioChannel.radioTour,
        priority: RadioPriority.info,
        senderName: 'Radio Tour',
        message: 'FLAMME ROUGE: 1 km do mety! Peleton szykuje się do sprintu.',
      );
      expect(RaceRadioEventDetector.shouldTriggerRadioBeep(msg), isTrue);
    });

    test('wykrywa defekt koła i przebicie opony', () {
      const msg = RaceRadioMessage(
        id: '4',
        kilometerMark: 95.0,
        elapsedSeconds: 7200.0,
        channel: RadioChannel.radioTour,
        priority: RadioPriority.warning,
        senderName: 'Radio Tour',
        message: 'Defekt mechaniczny: przebita opona u sprintera.',
      );
      expect(RaceRadioEventDetector.shouldTriggerRadioBeep(msg), isTrue);
    });

    test('ignoruje rutynowe komunikaty neutralne bez słów kluczowych', () {
      const msg = RaceRadioMessage(
        id: '5',
        kilometerMark: 60.0,
        elapsedSeconds: 4800.0,
        channel: RadioChannel.motoTimekeeper,
        priority: RadioPriority.info,
        senderName: 'Moto Info',
        message: 'Różnica czasu: ucieczka jedzie 2 minuty przed peletonem.',
      );
      expect(RaceRadioEventDetector.shouldTriggerRadioBeep(msg), isFalse);
    });
  });

  group('BikeComputerAlertTracker - Wykrywanie ClimbPro oraz W\' < 15%', () {
    late BikeComputerAlertTracker tracker;

    const testSegments = [
      StageSegment(
        index: 0,
        startKm: 0.0,
        lengthKm: 20.0,
        startElevationM: 200.0,
        endElevationM: 250.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 10.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none,
      ),
      StageSegment(
        index: 1,
        startKm: 20.0,
        lengthKm: 8.5,
        startElevationM: 250.0,
        endElevationM: 980.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 40.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.cat1, // Kategoryzowany podjazd kat. 1
      ),
      StageSegment(
        index: 2,
        startKm: 28.5,
        lengthKm: 15.0,
        startElevationM: 980.0,
        endElevationM: 300.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
        technicalDifficulty: 60.0,
        windDirectionDegrees: 0.0,
        roadBearingDegrees: 0.0,
        sprintOrKomClassification: SegmentClassification.none, // Zjazd
      ),
    ];

    setUp(() {
      tracker = BikeComputerAlertTracker();
    });

    test('wjazd na kategoryzowany podjazd Cat 1 generuje ClimbPro Alert', () {
      // 1. Jazda po płaskim (KM 10.0) -> brak alarmu
      final alertsFlat = tracker.processTelemetry(
        currentKm: 10.0,
        wPrimePercent: 0.95,
        segments: testSegments,
      );
      expect(alertsFlat, isEmpty);

      // 2. Przekroczenie KM 20.0 (wjazd na podjazd kat. 1) -> ClimbPro alert!
      final alertsClimbStart = tracker.processTelemetry(
        currentKm: 20.1,
        wPrimePercent: 0.95,
        segments: testSegments,
      );
      expect(alertsClimbStart, contains(RadioSoundType.climbProAlert));

      // 3. Dalsza jazda po podjeździe (KM 22.0) -> nie powtarza alarmu na tym samym segmencie
      final alertsClimbContinue = tracker.processTelemetry(
        currentKm: 22.0,
        wPrimePercent: 0.90,
        segments: testSegments,
      );
      expect(alertsClimbContinue.contains(RadioSoundType.climbProAlert), isFalse);
    });

    test('spadek energii beztlenowej W\' poniżej 15% wyzwala alarm wPrimeCriticalAlarm', () {
      // 1. Zapas energii 40% -> brak alarmu
      final safeAlerts = tracker.processTelemetry(
        currentKm: 15.0,
        wPrimePercent: 0.40,
        segments: testSegments,
      );
      expect(safeAlerts, isEmpty);

      // 2. Spadek do 12% (< 15%) -> alarm!
      final criticalAlerts = tracker.processTelemetry(
        currentKm: 15.2,
        wPrimePercent: 0.12,
        segments: testSegments,
      );
      expect(criticalAlerts, contains(RadioSoundType.wPrimeCriticalAlarm));

      // 3. Kolejny krok przy 11% w trakcie trwania cooldownu -> nie dubluje alarmu
      final cooldownAlerts = tracker.processTelemetry(
        currentKm: 15.4,
        wPrimePercent: 0.11,
        segments: testSegments,
        dtSeconds: 1.0,
      );
      expect(cooldownAlerts.contains(RadioSoundType.wPrimeCriticalAlarm), isFalse);

      // 4. Upływ czasu cooldownu (18 sekund) podczas gdy W' nadal jest < 15% -> ponowny alarm ostrzegawczy
      final afterCooldownAlerts = tracker.processTelemetry(
        currentKm: 15.6,
        wPrimePercent: 0.08,
        segments: testSegments,
        dtSeconds: 20.0,
      );
      expect(afterCooldownAlerts, contains(RadioSoundType.wPrimeCriticalAlarm));
    });
  });

  group('RaceRadioAudioController - Główny Kontroler Radia i Powiadomień', () {
    late RaceRadioAudioController controller;

    setUp(() {
      controller = RaceRadioAudioController();
    });

    test('handleRadioMessage odtwarza "Krrr-beep!" i rejestruje komunikat w historii', () {
      AudioStereoBuffer? generatedBuffer;
      String? spokenText;

      controller.onAudioBufferGenerated = (buf, type) {
        generatedBuffer = buf;
      };
      controller.onTtsRequested = (text) {
        spokenText = text;
      };

      const attackMsg = RaceRadioMessage(
        id: 'radio_attack_1',
        kilometerMark: 135.0,
        elapsedSeconds: 11000.0,
        channel: RadioChannel.radioTour,
        priority: RadioPriority.urgent,
        senderName: 'Radio Tour',
        message: 'ATAK! Tadej Pogacar zaatakował na podjeździe!',
      );

      final resultBuffer = controller.handleRadioMessage(attackMsg);
      expect(resultBuffer, isNotNull);
      expect(generatedBuffer, isNotNull);
      expect(spokenText, contains('Radio Tour. ATAK! Tadej Pogacar zaatakował na podjeździe!'));
      expect(controller.history.length, equals(1));
      expect(controller.history.first.soundType, equals(RadioSoundType.squelchRogerBeep));
    });

    test('isRadioBeepEnabled = false wyłącza odtwarzanie dźwięków krótkofalówki', () {
      controller.isRadioBeepEnabled = false;

      const attackMsg = RaceRadioMessage(
        id: 'radio_attack_2',
        kilometerMark: 135.0,
        elapsedSeconds: 11000.0,
        channel: RadioChannel.radioTour,
        priority: RadioPriority.urgent,
        senderName: 'Radio Tour',
        message: 'Kraksa w peletonie!',
      );

      final buffer = controller.handleRadioMessage(attackMsg);
      expect(buffer, isNull);
      expect(controller.history, isEmpty);
    });

    test('handleBikeComputerTelemetry poprawnie deleguje sygnały ClimbPro i W\' Alert', () {
      final buffers = controller.handleBikeComputerTelemetry(
        currentKm: 10.0,
        wPrimePercent: 0.10, // < 15% -> Alarm W'
        segments: const [],
      );

      expect(buffers.length, equals(1));
      expect(controller.history.length, equals(1));
      expect(controller.history.first.soundType, equals(RadioSoundType.wPrimeCriticalAlarm));
    });

    test('reset zeruje historię i stan trackerów', () {
      controller.handleBikeComputerTelemetry(
        currentKm: 10.0,
        wPrimePercent: 0.05,
        segments: const [],
      );
      expect(controller.history.isNotEmpty, isTrue);

      controller.reset();
      expect(controller.history, isEmpty);
    });
  });
}
