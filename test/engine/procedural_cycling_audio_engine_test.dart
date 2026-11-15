// Copyright (c) 2026 Pro Peloton Manager. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pro_peloton_manager/engine/audio/procedural_cycling_audio_engine.dart';
import 'package:pro_peloton_manager/models/race/race_stage.dart';
import 'package:pro_peloton_manager/models/race/stage_segment.dart';

void main() {
  group('CyclingAudioTelemetry - Modele i Właściwości Fizyczne', () {
    test('poprawnie wyznacza prędkość w m/s oraz częstotliwość obrotu koła 700c', () {
      const telemetry = CyclingAudioTelemetry(speedKmh: 45.0);
      expect(telemetry.speedMs, closeTo(12.5, 0.01));

      // Obwód koła 700c ~ 2.13m -> 12.5 / 2.13 ≈ 5.868 Hz
      expect(telemetry.wheelRotationalFrequencyHz, closeTo(5.868, 0.05));
    });

    test('isCoasting poprawnie wykrywa bieg jałowy / brak pedałowania na zjeździe i zakręcie', () {
      // 1. Kolarz pedałuje z mocą (nie ma biegu jałowego)
      const pedaling = CyclingAudioTelemetry(
        speedKmh: 44.0,
        cadenceRpm: 92.0,
        powerWatts: 380.0,
      );
      expect(pedaling.isCoasting, isFalse);

      // 2. Kolarz zjeżdża z góry z zerową kadencją (bieg jałowy aktywny)
      const descentCoasting = CyclingAudioTelemetry(
        speedKmh: 68.0,
        cadenceRpm: 0.0,
        powerWatts: 0.0,
      );
      expect(descentCoasting.isCoasting, isTrue);

      // 3. Kolarz kręci "na pusto" bez obciążenia w zakręcie (niska kadencja i znikoma moc)
      const softSpinCoasting = CyclingAudioTelemetry(
        speedKmh: 36.0,
        cadenceRpm: 12.0,
        powerWatts: 10.0,
      );
      expect(softSpinCoasting.isCoasting, isTrue);

      // 4. Rower stoi w miejscu (speed < 3.5 km/h) -> nie ma odgłosu biegu jałowego
      const stationary = CyclingAudioTelemetry(
        speedKmh: 1.0,
        cadenceRpm: 0.0,
        powerWatts: 0.0,
      );
      expect(stationary.isCoasting, isFalse);
    });

    test('copyWith i fabryki demonstracyjne tworzą poprawne instancje telemetrii', () {
      final sprint = CyclingAudioTelemetry.demoSprint();
      expect(sprint.speedKmh, greaterThan(60.0));
      expect(sprint.isCoasting, isFalse);

      final descent = CyclingAudioTelemetry.demoDescentCoasting();
      expect(descent.speedKmh, greaterThan(70.0));
      expect(descent.isCoasting, isTrue);

      final cobble = CyclingAudioTelemetry.demoCobblestones();
      expect(cobble.surfaceType, equals(SegmentSurfaceType.cobblestonesSector5));

      final rain = CyclingAudioTelemetry.demoRainStorm();
      expect(rain.weatherCondition, equals(WeatherCondition.heavyStorm));

      final modified = sprint.copyWith(speedKmh: 55.0, rimDepthMm: 80.0);
      expect(modified.speedKmh, equals(55.0));
      expect(modified.rimDepthMm, equals(80.0));
      expect(modified.cadenceRpm, equals(sprint.cadenceRpm));
    });
  });

  group('AudioStereoBuffer - Próbkowanie i Eksport Kontenera WAV / WebAudio', () {
    test('poprawnie konwertuje próbki Float32 na przeplatany bufor 16-bit PCM ze znakiem', () {
      final left = Float32List.fromList([-1.0, 0.0, 0.5, 1.0]);
      final right = Float32List.fromList([-0.5, 0.25, 0.0, -1.0]);
      final buffer = AudioStereoBuffer(left: left, right: right, sampleRate: 44100);

      expect(buffer.frameCount, equals(4));
      expect(buffer.durationSeconds, closeTo(4 / 44100, 1e-6));

      final pcm16 = buffer.toInterleavedPcm16();
      expect(pcm16.length, equals(8)); // 4 klatki * 2 kanały

      // Sprawdzenie skrajnych wartości 16-bit PCM (-32768 do 32767)
      expect(pcm16[0], equals(-32767)); // Left[0] = -1.0
      expect(pcm16[1], equals(-16384)); // Right[0] = -0.5
      expect(pcm16[6], equals(32767)); // Left[3] = 1.0
      expect(pcm16[7], equals(-32767)); // Right[3] = -1.0
    });

    test('toWavBytes generuje poprawny 44-bajtowy nagłówek RIFF/WAVE i sekcję DATA', () {
      const frameCount = 100;
      final left = Float32List(frameCount);
      final right = Float32List(frameCount);
      final buffer = AudioStereoBuffer(left: left, right: right, sampleRate: 44100);

      final wavBytes = buffer.toWavBytes();
      // Oczekiwany rozmiar: 44 bajty nagłówka + (100 ramek * 2 kanały * 2 bajty) = 44 + 400 = 444 bajty
      expect(wavBytes.length, equals(44 + 400));

      // 1. Sprawdzenie sygnatury RIFF
      final riffHeader = String.fromCharCodes(wavBytes.sublist(0, 4));
      expect(riffHeader, equals('RIFF'));

      // 2. Sprawdzenie formatu WAVE
      final waveHeader = String.fromCharCodes(wavBytes.sublist(8, 12));
      expect(waveHeader, equals('WAVE'));

      // 3. Sprawdzenie subchunka fmt
      final fmtHeader = String.fromCharCodes(wavBytes.sublist(12, 16));
      expect(fmtHeader, equals('fmt '));

      final bdata = ByteData.view(wavBytes.buffer);
      expect(bdata.getUint16(20, Endian.little), equals(1)); // Format PCM
      expect(bdata.getUint16(22, Endian.little), equals(2)); // Stereo (2 kanały)
      expect(bdata.getUint32(24, Endian.little), equals(44100)); // Sample rate
      expect(bdata.getUint16(34, Endian.little), equals(16)); // 16-bit

      // 4. Sprawdzenie subchunka data
      final dataHeader = String.fromCharCodes(wavBytes.sublist(36, 40));
      expect(dataHeader, equals('data'));
      expect(bdata.getUint32(40, Endian.little), equals(400));
    });

    test('toDataUri generuje poprawny nagłówek data:audio/wav;base64', () {
      final left = Float32List(20);
      final right = Float32List(20);
      final buffer = AudioStereoBuffer(left: left, right: right, sampleRate: 44100);

      final uri = buffer.toDataUri();
      expect(uri.startsWith('data:audio/wav;base64,'), isTrue);

      final base64Payload = uri.substring('data:audio/wav;base64,'.length);
      final decodedBytes = base64Decode(base64Payload);
      expect(decodedBytes.length, equals(44 + 80));
    });
  });

  group('CarbonWheelAeroGenerator - Szum Kół Karbonowych (Aero Whoosh)', () {
    late CarbonWheelAeroGenerator generator;

    setUp(() {
      generator = CarbonWheelAeroGenerator();
    });

    test('poniżej 35 km/h generator kół karbonowych jest wyciszony', () {
      const dt = 1.0 / 44100.0;
      const telLowSpeed = CyclingAudioTelemetry(speedKmh: 30.0);

      for (int i = 0; i < 500; i++) {
        final frame = generator.processSample(telemetry: telLowSpeed, dt: dt);
        expect(frame.left, equals(0.0));
        expect(frame.right, equals(0.0));
      }
    });

    test('powyżej 40 km/h szum kół karbonowych narasta wraz ze wzrostem prędkości', () {
      const dt = 1.0 / 44100.0;

      // Generowanie próbek dla 45 km/h
      generator.reset();
      double energy45 = 0.0;
      const tel45 = CyclingAudioTelemetry(speedKmh: 45.0, rimDepthMm: 60.0);
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: tel45, dt: dt);
        energy45 += (frame.left * frame.left) + (frame.right * frame.right);
      }

      // Generowanie próbek dla 65 km/h
      generator.reset();
      double energy65 = 0.0;
      const tel65 = CyclingAudioTelemetry(speedKmh: 65.0, rimDepthMm: 60.0);
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: tel65, dt: dt);
        energy65 += (frame.left * frame.left) + (frame.right * frame.right);
      }

      expect(energy45, greaterThan(0.01));
      expect(energy65, greaterThan(energy45 * 1.5));
    });

    test('wyższy stożek obręczy karbonowej generuje silniejszy rezonans pudła aerodynamicznego', () {
      const dt = 1.0 / 44100.0;

      // Niski stożek (35mm)
      generator.reset();
      double energy35mm = 0.0;
      const tel35 = CyclingAudioTelemetry(speedKmh: 50.0, rimDepthMm: 35.0);
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: tel35, dt: dt);
        energy35mm += (frame.left * frame.left) + (frame.right * frame.right);
      }

      // Wysoki stożek (80mm)
      generator.reset();
      double energy80mm = 0.0;
      const tel80 = CyclingAudioTelemetry(speedKmh: 50.0, rimDepthMm: 80.0);
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: tel80, dt: dt);
        energy80mm += (frame.left * frame.left) + (frame.right * frame.right);
      }

      expect(energy80mm, greaterThan(energy35mm * 1.3));
    });
  });

  group('FreehubRatchetGenerator - Terkot Bębenka Piasty (Freehub Buzz)', () {
    late FreehubRatchetGenerator generator;

    setUp(() {
      generator = FreehubRatchetGenerator();
    });

    test('podczas aktywnego pedałowania kolarza bębenek piasty milczy', () {
      const dt = 1.0 / 44100.0;
      const telPedaling = CyclingAudioTelemetry(
        speedKmh: 48.0,
        cadenceRpm: 94.0,
        powerWatts: 420.0,
      );

      for (int i = 0; i < 2000; i++) {
        final frame = generator.processSample(telemetry: telPedaling, dt: dt);
        expect(frame.left.abs(), lessThan(0.001));
        expect(frame.right.abs(), lessThan(0.001));
      }
    });

    test('gdy kolarz przestaje pedałować na zjeździe bębenek piasty zaczyna terkotać', () {
      const dt = 1.0 / 44100.0;
      const telCoasting = CyclingAudioTelemetry(
        speedKmh: 52.0,
        cadenceRpm: 0.0,
        powerWatts: 0.0,
        freehubTeethCount: 54,
      );

      double maxPeak = 0.0;
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: telCoasting, dt: dt);
        maxPeak = math.max(maxPeak, math.max(frame.left.abs(), frame.right.abs()));
      }

      expect(maxPeak, greaterThan(0.2));
    });

    test('bębenek piasty ma asymetrię panoramy stereo ku prawej stronie napędu', () {
      const dt = 1.0 / 44100.0;
      const telCoasting = CyclingAudioTelemetry(
        speedKmh: 50.0,
        cadenceRpm: 0.0,
        powerWatts: 0.0,
      );

      double sumLeft = 0.0;
      double sumRight = 0.0;
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: telCoasting, dt: dt);
        sumLeft += frame.left.abs();
        sumRight += frame.right.abs();
      }

      expect(sumRight, greaterThan(sumLeft));
    });
  });

  group('CobblestoneRumbleGenerator - Bruk Pavé i Szuter Strade Bianche', () {
    late CobblestoneRumbleGenerator generator;

    setUp(() {
      generator = CobblestoneRumbleGenerator();
    });

    test('na gładkim asfalcie generator bruku jest nieaktywny', () {
      const dt = 1.0 / 44100.0;
      const telAsphalt = CyclingAudioTelemetry(
        speedKmh: 45.0,
        surfaceType: SegmentSurfaceType.smoothAsphalt,
      );

      for (int i = 0; i < 1000; i++) {
        final frame = generator.processSample(telemetry: telAsphalt, dt: dt);
        expect(frame.left, equals(0.0));
        expect(frame.right, equals(0.0));
      }
    });

    test('sektor 5 bruku (Trouée d\'Arenberg) generuje potężniejsze wstrząsy niż sektor 1', () {
      const dt = 1.0 / 44100.0;

      // Sektor 1 bruku
      generator.reset();
      double energySector1 = 0.0;
      const telSec1 = CyclingAudioTelemetry(
        speedKmh: 42.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector1,
      );
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: telSec1, dt: dt);
        energySector1 += (frame.left * frame.left) + (frame.right * frame.right);
      }

      // Sektor 5 bruku (5 gwiazdek)
      generator.reset();
      double energySector5 = 0.0;
      const telSec5 = CyclingAudioTelemetry(
        speedKmh: 42.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
      );
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: telSec5, dt: dt);
        energySector5 += (frame.left * frame.left) + (frame.right * frame.right);
      }

      expect(energySector1, greaterThan(0.01));
      expect(energySector5, greaterThan(energySector1 * 1.8));
    });

    test('szuter Strade Bianche generuje chrzęst i szum kamieni', () {
      const dt = 1.0 / 44100.0;
      const telGravel = CyclingAudioTelemetry(
        speedKmh: 40.0,
        surfaceType: SegmentSurfaceType.gravelStrade,
      );

      double peak = 0.0;
      for (int i = 0; i < 2000; i++) {
        final frame = generator.processSample(telemetry: telGravel, dt: dt);
        peak = math.max(peak, frame.left.abs());
      }
      expect(peak, greaterThan(0.1));
    });
  });

  group('RainAndWaterSprayGenerator - Deszcz i Pióropusze Wody', () {
    late RainAndWaterSprayGenerator generator;

    setUp(() {
      generator = RainAndWaterSprayGenerator();
    });

    test('w suchy dzień (sunny / overcast) dźwięk deszczu nie jest generowany', () {
      const dt = 1.0 / 44100.0;
      const telSunny = CyclingAudioTelemetry(
        speedKmh: 40.0,
        weatherCondition: WeatherCondition.sunny,
      );

      for (int i = 0; i < 1000; i++) {
        final frame = generator.processSample(telemetry: telSunny, dt: dt);
        expect(frame.left, equals(0.0));
      }
    });

    test('w czasie burzy (heavyStorm) generowany jest głośny szum deszczu i pryskającej wody', () {
      const dt = 1.0 / 44100.0;
      const telStorm = CyclingAudioTelemetry(
        speedKmh: 45.0,
        weatherCondition: WeatherCondition.heavyStorm,
      );

      double energy = 0.0;
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: telStorm, dt: dt);
        energy += (frame.left * frame.left) + (frame.right * frame.right);
      }

      expect(energy, greaterThan(0.05));
    });
  });

  group('CrowdRoarGenerator - Wrzawa Kibiców i Strefa Mety (< 500m)', () {
    late CrowdRoarGenerator generator;

    setUp(() {
      generator = CrowdRoarGenerator();
    });

    test('daleko od mety (> 1500m) wrzawa kibiców jest wyciszona', () {
      const dt = 1.0 / 44100.0;
      const telFar = CyclingAudioTelemetry(
        speedKmh: 45.0,
        distanceRemainingMeters: 4500.0,
      );

      for (int i = 0; i < 1000; i++) {
        final frame = generator.processSample(telemetry: telFar, dt: dt);
        expect(frame.left, equals(0.0));
      }
    });

    test('na ostatnich 500 metrach przed metą wrzawa i barierki eksplodują głośnością', () {
      const dt = 1.0 / 44100.0;

      // 800m do mety
      generator.reset();
      double energy800m = 0.0;
      const tel800 = CyclingAudioTelemetry(distanceRemainingMeters: 800.0);
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: tel800, dt: dt);
        energy800m += (frame.left * frame.left) + (frame.right * frame.right);
      }

      // 150m do mety (kulminacja finiszu)
      generator.reset();
      double energy150m = 0.0;
      const tel150 = CyclingAudioTelemetry(distanceRemainingMeters: 150.0);
      for (int i = 0; i < 4410; i++) {
        final frame = generator.processSample(telemetry: tel150, dt: dt);
        energy150m += (frame.left * frame.left) + (frame.right * frame.right);
      }

      expect(energy800m, greaterThan(0.01));
      expect(energy150m, greaterThan(energy800m * 1.5));
    });
  });

  group('ProceduralCyclingAudioEngine - Mikser Główny i Bezpieczeństwo Obliczeń', () {
    late ProceduralCyclingAudioEngine audioEngine;

    setUp(() {
      audioEngine = ProceduralCyclingAudioEngine(sampleRate: 44100);
    });

    test('flaga isMuted natychmiast wycisza wszystkie kanały', () {
      audioEngine.isMuted = true;
      final buffer = audioEngine.generateAudioBuffer(
        duration: const Duration(milliseconds: 100),
        telemetry: CyclingAudioTelemetry.demoSprint(),
      );

      for (int i = 0; i < buffer.frameCount; i++) {
        expect(buffer.left[i], equals(0.0));
        expect(buffer.right[i], equals(0.0));
      }
    });

    test('masterVolume poprawnie skaluje wyjście miksera', () {
      audioEngine.masterVolume = 0.5;
      final bufferHalf = audioEngine.generateAudioBuffer(
        duration: const Duration(milliseconds: 100),
        telemetry: CyclingAudioTelemetry.demoSprint(),
      );

      audioEngine.reset();
      audioEngine.masterVolume = 1.0;
      final bufferFull = audioEngine.generateAudioBuffer(
        duration: const Duration(milliseconds: 100),
        telemetry: CyclingAudioTelemetry.demoSprint(),
      );

      double sumHalf = 0.0;
      double sumFull = 0.0;
      for (int i = 0; i < bufferHalf.frameCount; i++) {
        sumHalf += bufferHalf.left[i].abs();
        sumFull += bufferFull.left[i].abs();
      }

      expect(sumHalf, greaterThan(0.0));
      expect(sumFull, greaterThan(sumHalf * 1.3));
    });

    test('Soft-Clipper zapobiega przekroczeniu dopuszczalnego zakresu [-1.0, 1.0]', () {
      // Ekstremalna sytuacja: sprint na bruku w ulewie 150m przed metą
      const extremeTelemetry = CyclingAudioTelemetry(
        speedKmh: 68.0,
        cadenceRpm: 120.0,
        powerWatts: 1400.0,
        surfaceType: SegmentSurfaceType.cobblestonesSector5,
        weatherCondition: WeatherCondition.heavyStorm,
        distanceRemainingMeters: 100.0,
        rimDepthMm: 80.0,
      );

      final buffer = audioEngine.generateAudioBuffer(
        duration: const Duration(milliseconds: 250),
        telemetry: extremeTelemetry,
      );

      for (int i = 0; i < buffer.frameCount; i++) {
        expect(buffer.left[i], inInclusiveRange(-1.0, 1.0));
        expect(buffer.right[i], inInclusiveRange(-1.0, 1.0));
      }
    });

    test('generateWavBytes tworzy w pełni poprawny plik WAV możliwy do odtworzenia', () {
      final wavBytes = audioEngine.generateWavBytes(
        duration: const Duration(milliseconds: 500),
        telemetry: CyclingAudioTelemetry.demoSprint(),
      );

      expect(wavBytes.length, greaterThan(44));
      // 0.5s * 44100 = 22050 ramek * 4 bajty = 88200 bajtów danych + 44 nagłówka
      expect(wavBytes.length, equals(44 + 88200));

      // Sprawdzenie nagłówka
      final tag = String.fromCharCodes(wavBytes.sublist(0, 4));
      expect(tag, equals('RIFF'));
    });

    test('generateDataUri zwraca zdekodowalny ciąg znaków Base64 dla WebAudio', () {
      final uri = audioEngine.generateDataUri(
        duration: const Duration(milliseconds: 100),
        telemetry: CyclingAudioTelemetry.demoDescentCoasting(),
      );

      expect(uri.startsWith('data:audio/wav;base64,'), isTrue);
    });
  });
}
